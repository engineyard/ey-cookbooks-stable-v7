#!/usr/bin/env ruby
# frozen_string_literal: true

# Integration tests for the ey-postgresql `pg_extension` resource (GHI-21914).
#
# These converge the REAL resource file with `chef-solo` against a REAL running
# PostgreSQL and assert the resulting database state. They cover all three
# Chef-17-era fixes made on PR #258:
#
#   1. Property access via `new_resource.*` inside `action :install`
#      (the original `NameError: undefined local variable or method 'ext_name'`).
#      Covered for BOTH single-string and Array-typed `ext_name`/`db_name`.
#   2. `VERSION '...'` / `FROM '...'` quoting in the CREATE EXTENSION command
#      (unquoted `VERSION 1.4` raised a PostgreSQL syntax error).
#   3. The `server_configure.rb` "process extensions.json" block using
#      `declare_resource(:ey_postgresql_pg_extension, ...)` instead of the stale
#      `Chef::Resource::PostgresqlPgExtension` constant (which raised
#      `uninitialized constant` under Chef 17 on every Apply with an
#      extensions.json).
#
# Requirements (see spec/README.md):
#   - `chef-solo` on PATH  (gem install chef chef-bin)
#   - a reachable PostgreSQL superuser `postgres`
#   - env: PGHOST/PGPORT (default socket) so `psql -U postgres` connects.
#     The bundled extensions used (hstore, pg_trgm) ship with core PostgreSQL,
#     so no PostGIS packages are required.
#
# Run:  ruby cookbooks/ey-postgresql/spec/pg_extension_integration_test.rb

require "minitest/autorun"
require "json"
require "tmpdir"
require "fileutils"

module PgExtHarness
  SPEC_DIR = __dir__
  EYPG_DIR = File.expand_path("..", SPEC_DIR)                       # cookbooks/ey-postgresql
  RESOURCE = File.join(EYPG_DIR, "resources", "pg_extension.rb")
  CREATEDB = File.join(EYPG_DIR, "resources", "createdb.rb")
  SERVER_CONFIGURE = File.join(EYPG_DIR, "recipes", "server_configure.rb")

  module_function

  def psql(sql, db: "postgres")
    out = `psql -U postgres -d #{db} -Atqc #{sql.inspect} 2>&1`
    raise "psql failed for #{sql.inspect}: #{out}" unless $?.success?
    out.strip
  end

  def reset_db(name)
    `psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS #{name} WITH (FORCE)" 2>&1`
    `psql -U postgres -d postgres -c "CREATE DATABASE #{name}" 2>&1`
    raise "could not create db #{name}" unless $?.success?
  end

  # Build a minimal, dependency-free cookbook tree containing ONLY the real
  # pg_extension resource plus stubs for what its action include_recipe's/calls,
  # then converge `recipe_body` against it. Returns the chef-solo output.
  def converge(recipe_body, node_attrs)
    Dir.mktmpdir("pgext-int") do |work|
      cb = File.join(work, "cookbooks")
      FileUtils.mkdir_p([
        File.join(cb, "ey-postgresql", "resources"),
        File.join(cb, "ey-postgresql", "recipes"),
        File.join(cb, "ey-postgresql", "libraries"),
        File.join(cb, "custom", "recipes"),
      ])

      FileUtils.cp(RESOURCE, File.join(cb, "ey-postgresql", "resources", "pg_extension.rb"))
      FileUtils.cp(CREATEDB, File.join(cb, "ey-postgresql", "resources", "createdb.rb"))
      File.write(File.join(cb, "ey-postgresql", "metadata.rb"), %(name "ey-postgresql"\nversion "0.0.0"\n))
      %w[postgis_build auto_explain pg_stat_statements].each do |r|
        File.write(File.join(cb, "ey-postgresql", "recipes", "#{r}.rb"), "# stub for integration test\n")
      end
      File.write(File.join(cb, "ey-postgresql", "libraries", "version_helpers.rb"), <<~RB)
        class Chef
          class Resource
            def postgres_version_lt?(_); false; end
            def postgres_version_gt?(_); false; end
          end
        end
      RB

      File.write(File.join(cb, "custom", "metadata.rb"), %(name "custom"\nversion "0.0.0"\ndepends "ey-postgresql"\n))
      File.write(File.join(cb, "custom", "recipes", "default.rb"), recipe_body)

      File.write(File.join(work, "solo.rb"), %(cookbook_path "#{cb}"\n))
      File.write(File.join(work, "node.json"), JSON.dump(node_attrs.merge("run_list" => ["recipe[custom::default]"])))

      out = `chef-solo -c #{File.join(work, "solo.rb").inspect} -j #{File.join(work, "node.json").inspect} --chef-license accept 2>&1`
      out
    end
  end

  # Chef embeds the entire node object into error output, which is megabytes of
  # noise. Keep only the human-relevant lines for assertion messages.
  def summarize(out)
    out.each_line.grep(/error|fail|NameError|uninitialized|syntax|psql|action install/i)
       .map { |l| l.strip[0, 200] }
       .first(15)
       .join("\n")
  end

  # Extract the real "process extensions.json" ruby_block from server_configure.rb
  # so the dynamic-construction path is tested against the actual shipped code.
  def extensions_json_block
    src = File.read(SERVER_CONFIGURE)
    block = src[/ruby_block "process extensions\.json".*?\n^end$/m]
    raise "could not extract 'process extensions.json' block from server_configure.rb" unless block
    block
  end

  BASE_NODE = {
    "dna" => { "instance_role" => "db_master" },
    "postgresql" => { "short_version" => "18" },
    "pg_ext_details" => { "postgis" => {}, "hstore" => {}, "pg_trgm" => {} },
    "engineyard" => { "environment" => { "ssh_username" => "postgres" } },
    "postgis" => { "package_name" => "x" },
  }.freeze
end

class PgExtensionIntegrationTest < Minitest::Test
  H = PgExtHarness

  # Assert `out` does not contain `pattern`, WITHOUT dumping chef's multi-megabyte
  # node object (which refute_match would echo). Show only summarized error lines.
  def refute_output(pattern, out, msg)
    assert_nil(out[pattern], "#{msg}\n#{H.summarize(out)}")
  end

  def refute_name_error(out)
    refute_output(/NameError/, out, "converge raised NameError (GHI-21914 regression):")
  end

  # Fix 1a: original reported case — single-string ext_name/db_name.
  def test_single_string_creates_extension
    H.reset_db("svcy")
    out = H.converge(<<~RB, H::BASE_NODE)
      ey_postgresql_pg_extension 'Get hstore' do
        ext_name 'hstore'
        db_name  'svcy'
      end
    RB
    refute_name_error(out)
    assert_equal "hstore", H.psql("SELECT extname FROM pg_extension WHERE extname='hstore'", db: "svcy"),
                 "hstore should be installed in svcy"
  end

  # Fix 1b: the Array-typed property path (properties are [String, Array]).
  # Must create every extension in every database.
  def test_array_values_create_all_combinations
    H.reset_db("svcy")
    H.reset_db("other")
    out = H.converge(<<~RB, H::BASE_NODE)
      ey_postgresql_pg_extension 'multi' do
        ext_name ['hstore', 'pg_trgm']
        db_name  ['svcy', 'other']
      end
    RB
    refute_name_error(out)
    %w[svcy other].each do |db|
      count = H.psql("SELECT count(*) FROM pg_extension WHERE extname IN ('hstore','pg_trgm')", db: db)
      assert_equal "2", count, "both hstore and pg_trgm should be installed in #{db}"
    end
  end

  # Fix 2: VERSION/FROM must be SQL-quoted. Unquoted `VERSION 1.4` was a syntax error.
  def test_pinned_version_and_schema
    H.reset_db("svcy")
    H.psql("CREATE SCHEMA IF NOT EXISTS ext", db: "svcy")
    version = H.psql("SELECT version FROM pg_available_extension_versions WHERE name='hstore' ORDER BY version LIMIT 1", db: "svcy")
    skip "no hstore versions available" if version.empty?
    out = H.converge(<<~RB, H::BASE_NODE)
      ey_postgresql_pg_extension 'Get hstore' do
        ext_name    'hstore'
        db_name     'svcy'
        schema_name 'ext'
        version     '#{version}'
      end
    RB
    refute_name_error(out)
    refute_output(/syntax error/, out, "CREATE EXTENSION must not produce a SQL syntax error (VERSION must be quoted):")
    assert_equal version, H.psql("SELECT extversion FROM pg_extension WHERE extname='hstore'", db: "svcy"),
                 "hstore should be pinned to #{version}"
    assert_equal "ext", H.psql("SELECT n.nspname FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace WHERE extname='hstore'", db: "svcy"),
                 "hstore should be created in schema ext"
  end

  # Fix 4: the sibling `createdb` resource had the same bare-property bug
  # (db_name/owner read as bare identifiers; note db_name was not even a declared
  # property — the DB name property is `name`). A customer-cookbook-style
  # invocation must create the database, no NameError.
  def test_createdb_creates_database
    H.psql("DROP DATABASE IF EXISTS createdb_spec WITH (FORCE)", db: "postgres")
    H.psql("DROP ROLE IF EXISTS deploy", db: "postgres")
    H.psql("CREATE ROLE deploy LOGIN", db: "postgres")
    out = H.converge(<<~RB, H::BASE_NODE)
      createdb 'make app db' do
        name  'createdb_spec'
        owner 'deploy'
      end
    RB
    refute_name_error(out)
    assert_equal "1",
                 H.psql("SELECT 1 FROM pg_database WHERE datname='createdb_spec'", db: "postgres"),
                 "createdb should create the database createdb_spec"
    assert_equal "deploy",
                 H.psql("SELECT pg_catalog.pg_get_userbyid(datdba) FROM pg_database WHERE datname='createdb_spec'", db: "postgres"),
                 "createdb should set the owner to deploy"
  end

  # Fix 3: the real "process extensions.json" block must resolve the resource
  # (declare_resource) and create the extensions — no `uninitialized constant`.
  def test_extensions_json_dynamic_path
    H.reset_db("svcy")
    Dir.mktmpdir("pgext-json") do |dir|
      ext_file = File.join(dir, "extensions.json")
      File.write(ext_file, JSON.dump("svcy" => %w[hstore pg_trgm]))
      node = H::BASE_NODE.merge("pg_extensions_file" => ext_file)
      out = H.converge(H.extensions_json_block, node)
      refute_name_error(out)
      refute_output(/uninitialized constant/, out,
                    "process extensions.json must not reference a stale resource constant:")
      count = H.psql("SELECT count(*) FROM pg_extension WHERE extname IN ('hstore','pg_trgm')", db: "svcy")
      assert_equal "2", count, "both extensions from extensions.json should be installed in svcy"
    end
  end
end
