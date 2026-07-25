# frozen_string_literal: true

namespace :loadtest do
  desc "Run a load test. rake 'loadtest:run[<config-name|site/env>,requests,concurrency,label]'"
  task :run, %i[target requests concurrency label] => :environment do |_t, args|
    target = args[:target] or abort "usage: rake 'loadtest:run[<config-name|site/env>,requests,concurrency,label]'"
    config, environment = resolve_target(target)
    abort "target not found: #{target}" unless config || environment

    executor = LoadTest::Executor.new(
      run_config: config, environment: environment,
      requests_per_url: args[:requests]&.to_i, concurrency: args[:concurrency]&.to_i,
      label: args[:label], allow_prod: ENV["ALLOW_PROD"] == "1",
      store_samples: ENV["STORE_SAMPLES"] == "1"
    )
    run = executor.call
    print_run(run)
  rescue LoadTest::Executor::ProductionNotAllowed => e
    abort "REFUSED: #{e.message}"
  end

  desc "Import a URL-list file into an environment. rake 'loadtest:import[path,SiteKey,envName]'"
  task :import, %i[path site env] => :environment do |_t, args|
    path = args[:path] or abort "usage: rake 'loadtest:import[path,SiteKey,envName]'"
    site = Site.find_or_create_by!(key: args[:site] || "Imported") { |s| s.name = args[:site] || "Imported" }
    env = site.environments.find_or_create_by!(name: args[:env] || "staging") do |e|
      e.base_url = ENV["BASE_URL"] || "https://example.com"
      e.is_production = args[:env].to_s.match?(/prod/i)
    end
    result = LoadTest::UrlListImporter.new(environment: env).import(path)
    summary = "imported into #{env.label}: #{result.created} created, #{result.updated} updated"
    summary += ", #{result.skipped} skipped (blank or foreign-host lines)" if result.skipped.positive?
    puts summary
  end

  desc "Compare two runs by id. rake 'loadtest:compare[before_id,after_id]'"
  task :compare, %i[before after] => :environment do |_t, args|
    before = Run.find(args[:before])
    after  = Run.find(args[:after])
    puts "before ##{before.id} (#{before.dyno_formation}) -> after ##{after.id} (#{after.dyno_formation})"
    printf("%-40s %14s %14s %12s\n", "PAGE", "avg ms (Δ)", "p95 ms (Δ)", "rps (Δ)")
    puts "-" * 84
    by_key = after.results.index_by { |r| [ r.method, r.path ] }
    before.results.order(p95_ms: :desc).each do |b|
      a = by_key[[ b.method, b.path ]]
      next unless a

      printf("%-40s %6d ->%6d %6d ->%6d %5.1f->%5.1f\n",
             b.path[0, 40], b.avg_ms, a.avg_ms, b.p95_ms, a.p95_ms, b.rps, a.rps)
    end
  end

  desc "Create a completed demo run with synthetic metrics (no network) — for demos/e2e"
  task demo_run: :environment do
    Rails.application.load_seed unless Site.exists?(key: "demo")
    environment = Environment.joins(:site).find_by(sites: { key: "demo" }, name: "staging")
    abort "demo staging environment missing (run rake db:seed)" unless environment

    fake_runner = Class.new do
      def initialize(**) = nil

      def call(method:, url:, body: nil)
        base = 120 + (url.length % 7) * 60
        { requests: 20, error_count: 0, rps: 8.0, min_ms: base, avg_ms: base + 60,
          p50_ms: base + 45, p90_ms: base + 140, p95_ms: base + 200, p99_ms: base + 260,
          max_ms: base + 320, stddev_ms: 35, dns_ms: 5, connect_ms: 12,
          server_ms: base + 20, transfer_ms: 3, codes: { 200 => 20 }, samples: [] }
      end
    end

    run = LoadTest::Executor.new(environment: environment, requests_per_url: 20, concurrency: 5,
                                 label: "demo-baseline", runner_class: fake_runner).call
    puts "demo run ##{run.id} created (#{run.results.count} results)"
  end

  def resolve_target(target)
    config = RunConfig.find_by(name: target)
    return [ config, nil ] if config

    site_key, env_name = target.split("/", 2)
    env = Environment.joins(:site).find_by(sites: { key: site_key }, name: env_name)
    [ nil, env ]
  end

  def print_run(run)
    puts "\nRun ##{run.id} | #{run.environment.label} | #{run.status} | dyno: #{run.dyno_formation.presence || 'n/a'}"
    printf("%-40s %-6s %4s %4s %7s %8s %8s %8s\n", "PAGE", "METH", "n", "err", "rps", "avg", "p95", "p99")
    puts "-" * 90
    run.results.order(p95_ms: :desc).each do |r|
      printf("%-40s %-6s %4d %4d %7.1f %8d %8d %8d\n",
             r.path[0, 40], r.method, r.requests, r.error_count, r.rps, r.avg_ms, r.p95_ms, r.p99_ms)
    end
  end
end
