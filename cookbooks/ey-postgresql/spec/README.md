# ey-postgresql regression tests

Self-contained checks that need only `chef-solo` on the PATH
(`gem install chef chef-bin`) — no ChefSpec / Test Kitchen / running database.

## pg_extension_regression.sh

Guards against GHI-21914: the `pg_extension` custom resource must read its
properties via `new_resource.*` inside `action :install`, otherwise Chef 17
raises `NameError: undefined local variable or method 'ext_name'` and normal
Apply fails for any custom cookbook that uses `pg_extension` (e.g. to install
PostGIS).

The script converges the resource with the customer's exact invocation (single
string values) and the array form. A PostgreSQL server is not required — the
run legitimately stops at the `psql` step with a connection error, which the
guard ignores; only a `NameError` (or failing to reach the resource) fails it.

```bash
cookbooks/ey-postgresql/spec/pg_extension_regression.sh   # exit 0 = pass
```
