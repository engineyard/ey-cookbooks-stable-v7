# ey-postgresql regression tests

Automated coverage for the `pg_extension` fixes made for GHI-21914 (Engine Yard
v7 `pg_extension` failing under Chef 17). Two layers:

| File | Needs a DB? | Covers |
|------|-------------|--------|
| `pg_extension_integration_test.rb` | **Yes** (live PostgreSQL) | All three fixes, asserted against real database state |
| `pg_extension_regression.sh` | No (chef-solo only) | Fast `NameError` gate for String + Array property forms |

Both run in CI on every PR touching `cookbooks/ey-postgresql/**` — see
`.github/workflows/ey-postgresql-tests.yml` (PostgreSQL service container,
Chef 17 via `spec/Gemfile`).

## The three fixes under test

1. **Property access** — `action :install` must read properties via
   `new_resource.*`. Bare `ext_name`/`db_name` raised
   `NameError: undefined local variable or method 'ext_name'` under Chef 17.
   Covered for **both** single-string and Array-typed values.
2. **SQL quoting** — `CREATE EXTENSION ... VERSION '<v>'` / `FROM '<v>'` must be
   quoted; unquoted `VERSION 1.4` was a PostgreSQL syntax error.
3. **Dynamic path** — `server_configure.rb`'s "process extensions.json" block
   must resolve the resource via `declare_resource(:ey_postgresql_pg_extension, …)`;
   the old `Chef::Resource::PostgresqlPgExtension` constant (a pre-rename name)
   raised `uninitialized constant` on every Apply that had an `extensions.json`.

## Running locally

Prerequisites: `chef-solo` on PATH (`cd spec && bundle install`), and — for the
integration test — a reachable PostgreSQL superuser `postgres`. The bundled
extensions used (`hstore`, `pg_trgm`) ship with core PostgreSQL, so no PostGIS
packages are required.

```bash
cd cookbooks/ey-postgresql/spec
bundle install

# Integration test (real DB). psql -U postgres must connect via PG* env vars:
PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=postgres \
  bundle exec ruby pg_extension_integration_test.rb

# Fast no-DB gate:
bundle exec ./pg_extension_regression.sh   # exit 0 = pass, 1 = regression
```

Each test is self-checking: reverting any one of the three fixes turns the
corresponding assertion red (verified during development).
