# frozen_string_literal: true

# Generic demo data — a safe, public example target. Replace with your own via the
# web UI or `rake loadtest:import`. thunderherd is project-agnostic.
demo = Site.find_or_create_by!(key: "demo") { |s| s.name = "Demo Project" }

staging = demo.environments.find_or_create_by!(name: "staging") do |e|
  e.base_url = "https://example.com"
  e.is_production = false
  e.description = "Public example.com — a safe demo target."
end

production = demo.environments.find_or_create_by!(name: "production") do |e|
  e.base_url = "https://example.com"
  e.is_production = true
  e.description = "Demo production — running against it requires an explicit opt-in."
end

[ "/", "/index.html" ].each { |path| staging.urls.find_or_create_by!(method: "GET", path: path) }
production.urls.find_or_create_by!(method: "GET", path: "/")

RunConfig.find_or_create_by!(name: "demo-staging-smoke") do |c|
  c.environment = staging
  c.requests_per_url = 20
  c.concurrency = 5
  c.description = "Quick smoke over the demo staging URLs."
end

puts "Seeded: #{Site.count} sites, #{Environment.count} environments, " \
     "#{Url.count} urls, #{RunConfig.count} run configs."
