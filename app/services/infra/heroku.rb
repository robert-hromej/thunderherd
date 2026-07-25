# frozen_string_literal: true

require "open3"
require "json"

module Infra
  # Optional Heroku integration: capture the dyno formation + deployed release of a
  # target app so a run knows the infra it measured. No-ops cleanly when the `heroku`
  # CLI is missing or no app is configured — the tool works fine without it.
  module Heroku
    module_function

    def available?
      !`command -v heroku`.strip.empty?
    end

    # [{ process_type:, size:, quantity: }, ...] from `heroku ps:scale -a <app>`
    def dyno_formation(app)
      return [] if app.blank? || !available?

      out, _err, status = Open3.capture3("heroku", "ps:scale", "-a", app)
      return [] unless status.success?

      out.strip.split.filter_map do |token| # "web=2:Standard-2X"
        m = token.match(/\A(?<type>[\w-]+)=(?<qty>\d+)(?::(?<size>[\w.-]+))?\z/)
        next unless m

        { process_type: m[:type], quantity: m[:qty].to_i, size: m[:size] || "unknown" }
      end
    end

    # { heroku_release:, git_sha:, description:, deployed_at: } or nil
    def latest_release(app)
      return nil if app.blank? || !available?

      out, _err, status = Open3.capture3("heroku", "releases", "-a", app, "-n", "1", "--json")
      return nil unless status.success?

      data = JSON.parse(out).first
      return nil unless data

      { heroku_release: "v#{data['version']}", git_sha: extract_sha(data),
        description: data["description"], deployed_at: data["created_at"] }
    rescue JSON::ParserError
      nil
    end

    # The release object carries no top-level commit — for git deploys the sha only
    # appears in the description ("Deploy 3abcdef"); the slug sub-resource is not
    # expanded by `heroku releases --json`.
    def extract_sha(data)
      data.dig("slug", "commit") || data["description"].to_s[/\ADeploy (\h{7,40})\z/, 1]
    end
  end
end
