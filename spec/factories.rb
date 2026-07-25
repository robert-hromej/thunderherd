# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    sequence(:key) { |n| "site-#{n}" }
    name { "Site #{key}" }
  end

  factory :environment do
    site
    sequence(:name) { |n| "env-#{n}" }
    base_url { "https://example.com" }
    is_production { false }

    factory :production_environment do
      is_production { true }
    end
  end

  factory :url do
    environment
    add_attribute(:method) { "GET" }
    sequence(:path) { |n| "/page-#{n}" }
    is_active { true }
  end

  factory :operator do
    sequence(:name) { |n| "Operator #{n}" }
    sequence(:email) { |n| "op#{n}@example.com" }
  end

  factory :machine do
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
    hostname { "test-machine" }
    os { "TestOS 1.0" }
    arch { "arm64" }
    cpu_model { "Test CPU" }
    cpu_cores { 8 }
    ram_mb { 16_384 }
  end

  factory :run_config do
    sequence(:name) { |n| "config-#{n}" }
    environment
    requests_per_url { 50 }
    concurrency { 10 }
    timeout_s { 30 }
  end

  factory :app_deploy do
    environment
    sequence(:heroku_release) { |n| "v#{n}" }
    git_sha { "abc1234def" }
    deployed_at { Time.current }
  end

  factory :run do
    environment
    requests_per_url { 50 }
    concurrency { 10 }
    timeout_s { 30 }
    tool { "hey" }
    tool_version { "hey 0.1.5" }
    harness_version { "0.1.0" }
    status { "completed" }
    started_at { Time.current }
    finished_at { Time.current }

    factory :running_run do
      status { "running" }
      finished_at { nil }
    end
  end

  factory :run_dyno do
    run
    process_type { "web" }
    size { "Standard-2X" }
    quantity { 2 }
  end

  factory :run_network do
    run
    kind { "wifi" }
    isp { "Test ISP" }
    downlink_mbps { 100.0 }
  end

  factory :result do
    run
    add_attribute(:method) { "GET" }
    sequence(:path) { |n| "/page-#{n}" }
    requests { 50 }
    error_count { 0 }
    rps { 10.0 }
    min_ms { 100 }
    avg_ms { 200 }
    p50_ms { 190 }
    p90_ms { 250 }
    p95_ms { 300 }
    p99_ms { 350 }
    max_ms { 400 }
    stddev_ms { 30 }
    dns_ms { 5 }
    connect_ms { 10 }
    server_ms { 150 }
    transfer_ms { 2 }
  end

  factory :result_status_code do
    result
    status_code { 200 }
    count { 50 }
  end

  factory :result_sample do
    result
    sequence(:seq) { |n| n }
    response_ms { 200 }
    status_code { 200 }
    offset_ms { 0 }
  end
end
