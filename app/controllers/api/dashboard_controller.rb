# frozen_string_literal: true

module Api
  class DashboardController < BaseController
    def index
      render json: {
        counts: {
          sites: Site.count,
          environments: Environment.count,
          runs: Run.count,
          completed_runs: Run.completed.count
        },
        latest_runs: VRunSummary.order(started_at: :desc).limit(8).map { |r| run_summary_json(r) },
        slowest_pages: slowest_pages
      }
    end

    private

    def slowest_pages
      Result.completed_runs
            .includes(run: { environment: :site })
            .order(p95_ms: :desc)
            .limit(10)
            .map do |r|
        { run_id: r.run_id, site: r.run.environment.site.key, env: r.run.environment.name,
          method: r[:method], path: r.path, p95_ms: r.p95_ms.to_f, rps: r.rps.to_f,
          error_count: r.error_count }
      end
    end
  end
end
