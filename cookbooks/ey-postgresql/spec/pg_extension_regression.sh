#!/usr/bin/env bash
# Regression guard for GHI-21914 — pg_extension NameError under Chef 17.
#
# Converges the ey-postgresql `pg_extension` custom resource with Chef Infra
# Client (Chef 17-compatible) using the customer's exact invocation (single
# string values) plus the array form, and FAILS if the run raises `NameError`
# for a resource property — the original bug, where `action :install` read its
# properties as bare locals instead of `new_resource.*`.
#
# A running PostgreSQL is NOT required: the converge legitimately stops at the
# psql step with a connection error, which this guard ignores. Only a NameError
# (or failing to reach the resource) fails the guard.
#
# Requires chef-solo on PATH:  gem install chef chef-bin
# Exit 0 = pass, 1 = regression, 2 = harness/setup error.
set -uo pipefail

SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EYPG="$(cd "$SPEC_DIR/.." && pwd)"                 # cookbooks/ey-postgresql
RES="$EYPG/resources/pg_extension.rb"
[ -f "$RES" ] || { echo "cannot find $RES" >&2; exit 2; }
command -v chef-solo >/dev/null || { echo "chef-solo not on PATH (gem install chef chef-bin)" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CB="$WORK/cookbooks"
mkdir -p "$CB/ey-postgresql/resources" "$CB/ey-postgresql/recipes" \
         "$CB/ey-postgresql/libraries" "$CB/custom/recipes"

# Minimal, dependency-free ey-postgresql containing ONLY the resource under test
# plus stubs for what its action include_recipe's / calls. This isolates the
# property-access path from the full cookbook's unrelated dependencies.
cp "$RES" "$CB/ey-postgresql/resources/pg_extension.rb"
cat > "$CB/ey-postgresql/metadata.rb" <<'RB'
name "ey-postgresql"
version "0.0.0"
RB
: > "$CB/ey-postgresql/recipes/postgis_build.rb"
: > "$CB/ey-postgresql/recipes/auto_explain.rb"
: > "$CB/ey-postgresql/recipes/pg_stat_statements.rb"
cat > "$CB/ey-postgresql/libraries/spec_regression_helpers.rb" <<'RB'
class Chef
  class Resource
    def postgres_version_lt?(_); false; end
    def postgres_version_gt?(_); false; end
  end
end
RB

cat > "$CB/custom/metadata.rb" <<'RB'
name "custom"
version "0.0.0"
depends "ey-postgresql"
RB
cat > "$CB/custom/recipes/default.rb" <<'RB'
ey_postgresql_pg_extension 'Get PostGIS' do
  ext_name 'postgis'
  db_name  'svcy'
end

ey_postgresql_pg_extension 'multi' do
  ext_name ['postgis', 'hstore']
  db_name  ['svcy', 'other']
end
RB

cat > "$WORK/solo.rb"  <<RB
cookbook_path "$CB"
RB
cat > "$WORK/node.json" <<'RB'
{
  "dna": { "instance_role": "db_master" },
  "postgresql": { "short_version": "18" },
  "pg_ext_details": { "postgis": {}, "hstore": {} },
  "engineyard": { "environment": { "ssh_username": "postgres" } },
  "postgis": { "package_name": "x" },
  "run_list": ["recipe[custom::default]"]
}
RB

OUT="$WORK/run.log"
chef-solo -c "$WORK/solo.rb" -j "$WORK/node.json" --chef-license accept >"$OUT" 2>&1

if ! grep -q "pg_extension\[Get PostGIS\] action install" "$OUT"; then
  echo "ERROR: pg_extension resource never converged — harness problem:" >&2
  tail -20 "$OUT" >&2
  exit 2
fi

if grep -q "NameError" "$OUT"; then
  echo "FAIL: pg_extension raised NameError (GHI-21914 regression):" >&2
  grep -m1 "undefined local variable or method" "$OUT" | sed 's/ for #.*//' >&2
  exit 1
fi

echo "PASS: pg_extension converged with no NameError (property reads are new_resource-qualified)"
exit 0
