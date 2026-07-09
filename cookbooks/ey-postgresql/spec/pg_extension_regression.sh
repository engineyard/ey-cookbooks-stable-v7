#!/usr/bin/env bash
# Regression guard for GHI-21914 — Chef-17 bare-property NameError in the
# ey-postgresql custom resources.
#
# Under Chef 17's custom-resource action DSL, reading a declared property as a
# bare identifier (not qualified with `new_resource.`) raises
# `NameError: undefined local variable or method '<prop>'` deterministically on
# every invocation. This bit two EY-authored public resources that customer
# cookbooks call directly:
#   - pg_extension (action :install)      — the originally reported defect
#   - createdb     (action :createdb_action) — same bug class, same customer-
#                                              cookbook trigger vector
#
# This guard converges each resource with Chef Infra Client (Chef 17-compatible)
# and FAILS if the run raises `NameError` for a property. The pg_extension
# String and Array forms are converged as SEPARATE runs: without a database the
# first resource's psql step aborts the converge, so a single recipe with both
# would never reach the second. Running them independently guarantees each
# property-access path is actually exercised. Each run also asserts its
# resource's action was reached, so a converge that dies early is a harness
# error (exit 2), never a silent pass.
#
# A running PostgreSQL is NOT required: each converge legitimately stops at the
# psql step with a connection error, which this guard ignores. Only a NameError
# (or failing to reach the resource) fails the guard.
#
# For full database-state coverage (extension/database actually created, VERSION
# quoting, the server_configure.rb dynamic path) run
# pg_extension_integration_test.rb against a live PostgreSQL. This script is the
# fast, dependency-light gate.
#
# Requires chef-solo on PATH:  gem install chef chef-bin
# Exit 0 = pass, 1 = regression, 2 = harness/setup error.
set -uo pipefail

SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EYPG="$(cd "$SPEC_DIR/.." && pwd)"                 # cookbooks/ey-postgresql
for f in resources/pg_extension.rb resources/createdb.rb; do
  [ -f "$EYPG/$f" ] || { echo "cannot find $EYPG/$f" >&2; exit 2; }
done
command -v chef-solo >/dev/null || { echo "chef-solo not on PATH (gem install chef chef-bin)" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CB="$WORK/cookbooks"
mkdir -p "$CB/ey-postgresql/resources" "$CB/ey-postgresql/recipes" \
         "$CB/ey-postgresql/libraries" "$CB/custom/recipes"

# Minimal, dependency-free ey-postgresql containing ONLY the resources under
# test plus stubs for what their actions include_recipe / call. This isolates
# the property-access path from the full cookbook's unrelated dependencies.
cp "$EYPG/resources/pg_extension.rb" "$CB/ey-postgresql/resources/pg_extension.rb"
cp "$EYPG/resources/createdb.rb"     "$CB/ey-postgresql/resources/createdb.rb"
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

cat > "$WORK/solo.rb" <<RB
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

# Converge one recipe body and check its resource reached its action without a
# NameError. Args: <label> <converged-line-substring> <recipe-body>
#   <converged-line-substring> e.g. "pg_extension[Get PostGIS] action install"
run_case() {
  local label="$1" converged="$2" recipe="$3"
  printf '%s\n' "$recipe" > "$CB/custom/recipes/default.rb"
  local out="$WORK/${label}.log"
  chef-solo -c "$WORK/solo.rb" -j "$WORK/node.json" --chef-license accept >"$out" 2>&1

  if ! grep -qF "$converged" "$out"; then
    echo "ERROR [$label]: resource never converged — harness problem:" >&2
    tail -20 "$out" >&2
    return 2
  fi
  if grep -q "NameError" "$out"; then
    echo "FAIL [$label]: raised NameError (GHI-21914 regression):" >&2
    grep -m1 "undefined local variable or method" "$out" | sed 's/ for #.*//' >&2
    return 1
  fi
  echo "  ok [$label]: reached action with no NameError"
  return 0
}

rc=0
run_case "pg_extension-single" "pg_extension[Get PostGIS] action install" \
"ey_postgresql_pg_extension 'Get PostGIS' do
  ext_name 'postgis'
  db_name  'svcy'
end" || rc=$?

run_case "pg_extension-array" "pg_extension[multi] action install" \
"ey_postgresql_pg_extension 'multi' do
  ext_name ['postgis', 'hstore']
  db_name  ['svcy', 'other']
end" || rc=$?

# createdb: same bug class, invoked the way a customer cookbook would.
# (The `name` property overrides the resource block string, so the converged
# line shows createdb[svcy], not createdb[make db].)
run_case "createdb" "createdb[svcy] action createdb_action" \
"createdb 'make db' do
  name  'svcy'
  owner 'deploy'
end" || rc=$?

if [ "$rc" -eq 0 ]; then
  echo "PASS: pg_extension and createdb property reads are new_resource-qualified"
fi
exit "$rc"
