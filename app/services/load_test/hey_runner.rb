# frozen_string_literal: true

require "open3"

module LoadTest
  # Wraps the `hey` CLI: fires N requests at ONE url and returns aggregated stats.
  # hey's `-o csv` prints one row per request:
  #   response-time, DNS+dialup, DNS, Request-write, Response-delay, Response-read, status-code, offset
  class HeyRunner
    class HeyNotAvailable < StandardError; end

    def self.available?
      !`command -v hey`.strip.empty?
    end

    def self.version
      return nil unless available?

      ver = `hey --version 2>/dev/null`.strip
      ver.match?(/\d/) ? "hey #{ver}" : "hey"
    rescue StandardError
      "hey"
    end

    def initialize(requests:, concurrency:, timeout: 30)
      @requests = requests
      @concurrency = [ concurrency, requests ].min
      @timeout = timeout
    end

    # Returns a Hash of metrics for the target (see #aggregate).
    def call(method:, url:, body: nil)
      raise HeyNotAvailable, "`hey` not found — install it (e.g. brew install hey)" unless self.class.available?

      aggregate(parse(run(method:, url:, body:)))
    end

    private

    def run(method:, url:, body:)
      cmd = [ "hey", "-n", @requests.to_s, "-c", @concurrency.to_s, "-t", @timeout.to_s,
             "-m", method, "-o", "csv" ]
      cmd += [ "-d", body, "-T", "application/json" ] if body
      cmd << url
      out, = Open3.capture2(*cmd)
      out
    end

    def parse(out)
      out.each_line.drop(1).map { |l| l.split(",") }.select { |r| r.size >= 8 }
    end

    # hey's CSV lists only COMPLETED responses — timed-out/refused requests emit no
    # row (and hey exits 0 even on total failure), so the shortfall vs @requests is
    # counted as errors; latency stats describe the surviving responses only.
    def aggregate(rows)
      return empty if rows.empty?

      samples = rows.each_with_index.map do |r, i|
        { seq: i + 1, response_ms: ms(r[0]), status_code: r[6].to_i,
          dns_ms: ms(r[2]), connect_ms: ms(r[1].to_f - r[2].to_f), server_ms: ms(r[4]),
          offset_ms: ms(r[7]) }
      end
      times = samples.map { |s| s[:response_ms] }.sort
      n = times.size
      avg = times.sum / n
      missing = [ @requests - n, 0 ].max

      {
        requests: n + missing,
        error_count: samples.count { |s| s[:status_code] < 200 || s[:status_code] >= 400 } + missing,
        rps: throughput(rows: rows, count: n),
        min_ms: times.first, avg_ms: avg,
        p50_ms: pct(sorted: times, percentile: 50), p90_ms: pct(sorted: times, percentile: 90),
        p95_ms: pct(sorted: times, percentile: 95), p99_ms: pct(sorted: times, percentile: 99),
        max_ms: times.last,
        stddev_ms: Math.sqrt(times.sum { |t| (t - avg)**2 } / n).round(2),
        dns_ms: avg_of(samples: samples, key: :dns_ms),
        connect_ms: avg_of(samples: samples, key: :connect_ms),
        server_ms: avg_of(samples: samples, key: :server_ms),
        transfer_ms: ms(rows.sum { |r| r[5].to_f } / n),
        codes: samples.each_with_object(Hash.new(0)) { |s, h| h[s[:status_code]] += 1 },
        samples: samples
      }
    end

    # No CSV rows at all: every attempted request failed at the transport level.
    def empty
      { requests: @requests, error_count: @requests, rps: 0, min_ms: 0, avg_ms: 0, p50_ms: 0,
        p90_ms: 0, p95_ms: 0, p99_ms: 0, max_ms: 0, stddev_ms: 0, dns_ms: 0, connect_ms: 0,
        server_ms: 0, transfer_ms: 0, codes: {}, samples: [] }
    end

    def throughput(rows:, count:)
      wall = rows.map { |r| r[7].to_f + r[0].to_f }.max
      wall.positive? ? (count / wall).round(2) : 0.0
    end

    def pct(sorted:, percentile:)
      return 0.0 if sorted.empty?

      sorted[[ ((sorted.size - 1) * percentile / 100.0).round, sorted.size - 1 ].min].round(2)
    end

    def avg_of(samples:, key:)
      (samples.sum { |s| s[key] } / samples.size).round(2)
    end

    def ms(seconds)
      (seconds.to_f * 1000).round(2)
    end
  end
end
