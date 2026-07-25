# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_25_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "http_method", ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]
  create_enum "net_kind", ["ethernet", "wifi", "cellular", "vpn", "unknown"]
  create_enum "run_status", ["running", "completed", "aborted", "failed"]

  create_table "app_deploys", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "deployed_at"
    t.text "description"
    t.bigint "environment_id", null: false
    t.text "git_sha"
    t.text "heroku_release"
    t.index ["environment_id", "heroku_release"], name: "index_app_deploys_on_environment_id_and_heroku_release", unique: true
    t.index ["environment_id"], name: "index_app_deploys_on_environment_id"
  end

  create_table "environments", force: :cascade do |t|
    t.text "base_url", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description"
    t.text "heroku_app"
    t.boolean "is_production", default: false, null: false
    t.text "name", null: false
    t.bigint "site_id", null: false
    t.index ["site_id", "name"], name: "index_environments_on_site_id_and_name", unique: true
    t.index ["site_id"], name: "index_environments_on_site_id"
  end

  create_table "machines", force: :cascade do |t|
    t.text "arch"
    t.integer "cpu_cores"
    t.text "cpu_model"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "fingerprint", null: false
    t.text "hostname"
    t.text "os"
    t.integer "ram_mb"
    t.index ["fingerprint"], name: "index_machines_on_fingerprint", unique: true
  end

  create_table "operators", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "email"
    t.text "name", null: false
    t.index ["email"], name: "index_operators_on_email", unique: true
  end

  create_table "result_samples", force: :cascade do |t|
    t.decimal "connect_ms", precision: 10, scale: 2
    t.decimal "dns_ms", precision: 10, scale: 2
    t.decimal "offset_ms", precision: 12, scale: 2
    t.decimal "response_ms", precision: 10, scale: 2, null: false
    t.bigint "result_id", null: false
    t.integer "seq", null: false
    t.decimal "server_ms", precision: 10, scale: 2
    t.integer "status_code", null: false
    t.index ["result_id"], name: "index_result_samples_on_result_id"
  end

  create_table "result_status_codes", primary_key: ["result_id", "status_code"], force: :cascade do |t|
    t.integer "count", null: false
    t.bigint "result_id", null: false
    t.integer "status_code", null: false
  end

  create_table "results", force: :cascade do |t|
    t.decimal "avg_ms", precision: 10, scale: 2
    t.decimal "connect_ms", precision: 10, scale: 2
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.decimal "dns_ms", precision: 10, scale: 2
    t.integer "error_count", default: 0, null: false
    t.virtual "error_rate", type: :decimal, precision: 6, scale: 4, as: "\nCASE\n    WHEN (requests > 0) THEN ((error_count)::numeric / (requests)::numeric)\n    ELSE (0)::numeric\nEND", stored: true
    t.decimal "max_ms", precision: 10, scale: 2
    t.enum "method", null: false, enum_type: "http_method"
    t.decimal "min_ms", precision: 10, scale: 2
    t.decimal "p50_ms", precision: 10, scale: 2
    t.decimal "p90_ms", precision: 10, scale: 2
    t.decimal "p95_ms", precision: 10, scale: 2
    t.decimal "p99_ms", precision: 10, scale: 2
    t.text "path", null: false
    t.integer "requests", null: false
    t.decimal "rps", precision: 10, scale: 2
    t.bigint "run_id", null: false
    t.decimal "server_ms", precision: 10, scale: 2
    t.decimal "stddev_ms", precision: 10, scale: 2
    t.decimal "transfer_ms", precision: 10, scale: 2
    t.bigint "url_id"
    t.index ["method", "path"], name: "results_path_idx"
    t.index ["run_id", "url_id"], name: "index_results_on_run_id_and_url_id", unique: true, where: "(url_id IS NOT NULL)"
    t.index ["run_id"], name: "index_results_on_run_id"
    t.index ["url_id"], name: "index_results_on_url_id"
  end

  create_table "run_config_urls", primary_key: ["run_config_id", "url_id"], force: :cascade do |t|
    t.bigint "run_config_id", null: false
    t.bigint "url_id", null: false
  end

  create_table "run_configs", force: :cascade do |t|
    t.integer "concurrency", default: 10, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description"
    t.bigint "environment_id", null: false
    t.boolean "is_active", default: true, null: false
    t.text "name", null: false
    t.integer "requests_per_url", default: 50, null: false
    t.integer "timeout_s", default: 30, null: false
    t.index ["environment_id"], name: "index_run_configs_on_environment_id"
    t.index ["name"], name: "index_run_configs_on_name", unique: true
  end

  create_table "run_dynos", force: :cascade do |t|
    t.text "process_type", null: false
    t.integer "quantity", null: false
    t.bigint "run_id", null: false
    t.text "size", null: false
    t.index ["run_id", "process_type"], name: "index_run_dynos_on_run_id_and_process_type", unique: true
    t.index ["run_id"], name: "index_run_dynos_on_run_id"
  end

  create_table "run_networks", id: false, force: :cascade do |t|
    t.text "city"
    t.text "country"
    t.decimal "downlink_mbps", precision: 8, scale: 2
    t.text "isp"
    t.enum "kind", default: "unknown", null: false, enum_type: "net_kind"
    t.timestamptz "measured_at"
    t.cidr "public_ip_cidr"
    t.decimal "rtt_ms", precision: 8, scale: 2
    t.bigint "run_id", null: false
    t.decimal "uplink_mbps", precision: 8, scale: 2
    t.index ["run_id"], name: "index_run_networks_on_run_id", unique: true
  end

  create_table "runs", force: :cascade do |t|
    t.integer "concurrency", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.bigint "deploy_id"
    t.bigint "environment_id", null: false
    t.timestamptz "finished_at"
    t.text "harness_version"
    t.boolean "is_baseline", default: false, null: false
    t.text "label"
    t.bigint "machine_id"
    t.text "notes"
    t.bigint "operator_id"
    t.integer "requests_per_url", null: false
    t.bigint "run_config_id"
    t.timestamptz "started_at", default: -> { "now()" }, null: false
    t.enum "status", default: "running", null: false, enum_type: "run_status"
    t.integer "timeout_s", default: 30, null: false
    t.text "tool", default: "hey", null: false
    t.text "tool_version"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["deploy_id"], name: "index_runs_on_deploy_id"
    t.index ["environment_id", "started_at"], name: "index_runs_on_environment_id_and_started_at", order: { started_at: :desc }
    t.index ["machine_id"], name: "index_runs_on_machine_id"
    t.index ["operator_id"], name: "index_runs_on_operator_id"
    t.index ["run_config_id"], name: "index_runs_on_run_config_id"
    t.index ["uuid"], name: "index_runs_on_uuid", unique: true
  end

  create_table "sites", force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "key", null: false
    t.text "name", null: false
    t.index ["key"], name: "index_sites_on_key", unique: true
  end

  create_table "urls", force: :cascade do |t|
    t.jsonb "body"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description"
    t.bigint "environment_id", null: false
    t.boolean "is_active", default: true, null: false
    t.enum "method", default: "GET", null: false, enum_type: "http_method"
    t.text "path", null: false
    t.index "environment_id, method, path, md5(COALESCE((body)::text, ''::text))", name: "urls_uniq", unique: true
    t.index ["environment_id"], name: "index_urls_on_environment_id"
  end

  add_foreign_key "app_deploys", "environments"
  add_foreign_key "environments", "sites"
  add_foreign_key "result_samples", "results", on_delete: :cascade
  add_foreign_key "result_status_codes", "results", on_delete: :cascade
  add_foreign_key "results", "runs", on_delete: :cascade
  add_foreign_key "results", "urls"
  add_foreign_key "run_config_urls", "run_configs", on_delete: :cascade
  add_foreign_key "run_config_urls", "urls", on_delete: :cascade
  add_foreign_key "run_configs", "environments"
  add_foreign_key "run_dynos", "runs", on_delete: :cascade
  add_foreign_key "run_networks", "runs", on_delete: :cascade
  add_foreign_key "runs", "app_deploys", column: "deploy_id"
  add_foreign_key "runs", "environments"
  add_foreign_key "runs", "machines"
  add_foreign_key "runs", "operators"
  add_foreign_key "runs", "run_configs"
  add_foreign_key "urls", "environments", on_delete: :cascade

  create_view "v_run_summary", sql_definition: <<-SQL
      SELECT r.id,
      r.uuid,
      s.key AS site,
      e.name AS env,
      e.heroku_app,
      r.started_at,
      r.finished_at,
      r.label,
      r.is_baseline,
      r.status,
      o.name AS operator,
      m.hostname AS machine,
      d.heroku_release,
      d.git_sha,
      ( SELECT string_agg(((((rd.process_type || '='::text) || rd.quantity) || ':'::text) || rd.size), ' '::text ORDER BY rd.process_type) AS string_agg
             FROM run_dynos rd
            WHERE (rd.run_id = r.id)) AS dynos,
      r.requests_per_url,
      r.concurrency,
      r.tool_version,
      ( SELECT count(*) AS count
             FROM results re
            WHERE (re.run_id = r.id)) AS pages,
      ( SELECT sum(re.error_count) AS sum
             FROM results re
            WHERE (re.run_id = r.id)) AS total_errors,
      ( SELECT round(avg(re.p95_ms)) AS round
             FROM results re
            WHERE (re.run_id = r.id)) AS avg_p95_ms
     FROM (((((runs r
       JOIN environments e ON ((e.id = r.environment_id)))
       JOIN sites s ON ((s.id = e.site_id)))
       LEFT JOIN operators o ON ((o.id = r.operator_id)))
       LEFT JOIN machines m ON ((m.id = r.machine_id)))
       LEFT JOIN app_deploys d ON ((d.id = r.deploy_id)));
  SQL
end
