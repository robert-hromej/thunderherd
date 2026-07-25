# frozen_string_literal: true

module RunSerialization
  extend ActiveSupport::Concern

  private

  def run_summary_json(row)
    {
      id: row.id, uuid: row.uuid, site: row.site, env: row.env, heroku_app: row.heroku_app,
      label: row.label, status: row.status, is_baseline: row.is_baseline,
      started_at: row.started_at, finished_at: row.finished_at,
      operator: row.operator, machine: row.machine, dynos: row.dynos,
      heroku_release: row.heroku_release, requests_per_url: row.requests_per_url,
      concurrency: row.concurrency, tool_version: row.tool_version,
      pages: row.pages.to_i, total_errors: row.total_errors.to_i, avg_p95_ms: row.avg_p95_ms&.to_f
    }
  end

  def result_json(result)
    {
      id: result.id, method: result[:method], path: result.path,
      requests: result.requests, error_count: result.error_count, error_rate: result.error_rate.to_f,
      status_codes: result.result_status_codes.to_h { |c| [ c.status_code, c.count ] }
    }.merge(Result::METRICS.index_with { |metric| result[metric].to_f })
  end

  def run_detail_json(run)
    # Sort in Ruby: an SQL order would spawn a fresh query and discard the
    # results/result_status_codes preload (N+1 on every detail poll).
    results = run.results.sort_by { |r| -r.p95_ms.to_f }
    {
      id: run.id, uuid: run.uuid,
      site: run.environment.site.key, env: run.environment.name,
      base_url: run.environment.base_url, heroku_app: run.environment.heroku_app,
      is_production: run.environment.is_production,
      label: run.label, status: run.status, is_baseline: run.is_baseline, notes: run.notes,
      started_at: run.started_at, finished_at: run.finished_at, duration_s: run.duration_s,
      requests_per_url: run.requests_per_url, concurrency: run.concurrency, timeout_s: run.timeout_s,
      tool: run.tool, tool_version: run.tool_version, harness_version: run.harness_version,
      operator: run.operator&.name, machine: run.machine&.label,
      dyno_formation: run.dyno_formation,
      dynos: run.run_dynos.map { |d| { process_type: d.process_type, size: d.size, quantity: d.quantity } },
      deploy: run.deploy&.label,
      network: run.run_network && {
        kind: run.run_network.kind, isp: run.run_network.isp,
        rtt_ms: run.run_network.rtt_ms&.to_f,
        downlink_mbps: run.run_network.downlink_mbps&.to_f,
        uplink_mbps: run.run_network.uplink_mbps&.to_f,
        city: run.run_network.city, country: run.run_network.country
      },
      summary: {
        pages: results.size,
        total_requests: results.sum(&:requests),
        total_errors: results.sum(&:error_count),
        max_p95_ms: results.map { |r| r.p95_ms.to_f }.max || 0,
        avg_p95_ms: (results.any? ? (results.sum { |r| r.p95_ms.to_f } / results.size).round : 0)
      },
      results: results.map { |r| result_json(r) }
    }
  end
end
