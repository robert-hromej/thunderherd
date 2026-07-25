# frozen_string_literal: true

class CreateThunderherdSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto"

    # Whatever the local `template1` carries gets copied into every new database and
    # then dumped into schema.rb. Drop the one extension that shows up in practice so
    # the checked-in schema stays machine-independent — nothing here uses it.
    reversible { |dir| dir.up { execute 'DROP EXTENSION IF EXISTS "dblink"' } }

    create_enum "http_method", %w[GET POST PUT PATCH DELETE HEAD]
    create_enum "run_status",  %w[running completed aborted failed]
    create_enum "net_kind",    %w[ethernet wifi cellular vpn unknown]

    create_table :sites do |t|
      t.text :key, null: false
      t.text :name, null: false
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index :key, unique: true
    end

    create_table :environments do |t|
      t.references :site, null: false, foreign_key: true
      t.text :name, null: false
      t.text :base_url, null: false
      t.text :heroku_app
      t.boolean :is_production, null: false, default: false
      t.text :description
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index %i[site_id name], unique: true
    end

    # URLs may repeat (method, path) when their bodies differ, so the body is part
    # of the uniqueness key.
    create_table :urls do |t|
      t.references :environment, null: false, foreign_key: { on_delete: :cascade }
      t.enum :method, enum_type: "http_method", null: false, default: "GET"
      t.text :path, null: false
      t.jsonb :body
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index "environment_id, method, path, md5(COALESCE((body)::text, ''::text))",
              name: "urls_uniq", unique: true
    end

    create_table :operators do |t|
      t.text :name, null: false
      t.text :email
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index :email, unique: true
    end

    create_table :machines do |t|
      t.text :fingerprint, null: false
      t.text :hostname
      t.text :os
      t.text :arch
      t.text :cpu_model
      t.integer :cpu_cores
      t.integer :ram_mb
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index :fingerprint, unique: true
    end

    create_table :run_configs do |t|
      t.text :name, null: false
      t.references :environment, null: false, foreign_key: true
      t.integer :requests_per_url, null: false, default: 50
      t.integer :concurrency, null: false, default: 10
      t.integer :timeout_s, null: false, default: 30
      t.text :description
      t.boolean :is_active, null: false, default: true
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index :name, unique: true
    end

    # No rows for a config means "every active URL of the environment".
    create_table :run_config_urls, primary_key: %i[run_config_id url_id] do |t|
      t.bigint :run_config_id, null: false
      t.bigint :url_id, null: false
    end
    add_foreign_key :run_config_urls, :run_configs, on_delete: :cascade
    add_foreign_key :run_config_urls, :urls, on_delete: :cascade

    create_table :app_deploys do |t|
      t.references :environment, null: false, foreign_key: true
      t.text :heroku_release
      t.text :git_sha
      t.timestamptz :deployed_at
      t.text :description
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index %i[environment_id heroku_release], unique: true
    end

    create_table :runs do |t|
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      # index: false — the composite below already covers environment_id.
      t.references :environment, null: false, foreign_key: true, index: false
      t.references :run_config, foreign_key: true
      t.references :operator, foreign_key: true
      t.references :machine, foreign_key: true
      t.bigint :deploy_id
      t.integer :requests_per_url, null: false
      t.integer :concurrency, null: false
      t.integer :timeout_s, null: false, default: 30
      t.text :tool, null: false, default: "hey"
      t.text :tool_version
      t.text :harness_version
      t.text :label
      t.boolean :is_baseline, null: false, default: false
      t.enum :status, enum_type: "run_status", null: false, default: "running"
      t.timestamptz :started_at, null: false, default: -> { "now()" }
      t.timestamptz :finished_at
      t.text :notes
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index :uuid, unique: true
      t.index %i[environment_id started_at], order: { started_at: :desc }
      t.index :deploy_id
    end
    add_foreign_key :runs, :app_deploys, column: :deploy_id

    create_table :run_dynos do |t|
      t.references :run, null: false, foreign_key: { on_delete: :cascade }
      t.text :process_type, null: false
      t.text :size, null: false
      t.integer :quantity, null: false
      t.index %i[run_id process_type], unique: true
    end

    create_table :run_networks, id: false do |t|
      t.bigint :run_id, null: false
      t.enum :kind, enum_type: "net_kind", null: false, default: "unknown"
      t.text :isp
      t.cidr :public_ip_cidr
      t.decimal :downlink_mbps, precision: 8, scale: 2
      t.decimal :uplink_mbps, precision: 8, scale: 2
      t.decimal :rtt_ms, precision: 8, scale: 2
      t.text :city
      t.text :country
      t.timestamptz :measured_at
      t.index :run_id, unique: true
    end
    add_foreign_key :run_networks, :runs, on_delete: :cascade

    # One row per measured URL. Uniqueness is keyed on the URL, not (method, path):
    # two URLs may share both and differ only by body.
    create_table :results do |t|
      t.references :run, null: false, foreign_key: { on_delete: :cascade }
      t.references :url, foreign_key: true
      t.enum :method, enum_type: "http_method", null: false
      t.text :path, null: false
      t.integer :requests, null: false
      t.integer :error_count, null: false, default: 0
      t.virtual :error_rate, type: :decimal, precision: 6, scale: 4,
                as: "CASE WHEN requests > 0 THEN (error_count::numeric / requests) ELSE 0 END", stored: true
      t.decimal :rps, precision: 10, scale: 2
      t.decimal :min_ms, precision: 10, scale: 2
      t.decimal :avg_ms, precision: 10, scale: 2
      t.decimal :p50_ms, precision: 10, scale: 2
      t.decimal :p90_ms, precision: 10, scale: 2
      t.decimal :p95_ms, precision: 10, scale: 2
      t.decimal :p99_ms, precision: 10, scale: 2
      t.decimal :max_ms, precision: 10, scale: 2
      t.decimal :stddev_ms, precision: 10, scale: 2
      t.decimal :dns_ms, precision: 10, scale: 2
      t.decimal :connect_ms, precision: 10, scale: 2
      t.decimal :server_ms, precision: 10, scale: 2
      t.decimal :transfer_ms, precision: 10, scale: 2
      t.timestamptz :created_at, null: false, default: -> { "now()" }
      t.index %i[method path], name: "results_path_idx"
      t.index %i[run_id url_id], unique: true, where: "url_id IS NOT NULL"
    end

    create_table :result_status_codes, primary_key: %i[result_id status_code] do |t|
      t.bigint :result_id, null: false
      t.integer :status_code, null: false
      t.integer :count, null: false
    end
    add_foreign_key :result_status_codes, :results, on_delete: :cascade

    # Opt-in raw per-request rows (STORE_SAMPLES=1) for true histograms.
    create_table :result_samples do |t|
      t.references :result, null: false, foreign_key: { on_delete: :cascade }
      t.integer :seq, null: false
      t.decimal :response_ms, precision: 10, scale: 2, null: false
      t.integer :status_code, null: false
      t.decimal :dns_ms, precision: 10, scale: 2
      t.decimal :connect_ms, precision: 10, scale: 2
      t.decimal :server_ms, precision: 10, scale: 2
      t.decimal :offset_ms, precision: 12, scale: 2
    end

    create_view :v_run_summary
  end
end
