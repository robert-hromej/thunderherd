# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadTest::HeyRunner do
  let(:header) do
    "response-time,DNS+dialup,DNS,Request-write,Response-delay,Response-read,status-code,offset"
  end
  let(:rows) do
    [
      "0.1,0.02,0.01,0.001,0.05,0.002,200,0.0",
      "0.2,0.02,0.01,0.001,0.06,0.002,200,0.1",
      "0.3,0.02,0.01,0.001,0.07,0.002,500,0.2",
      "0.4,0.02,0.01,0.001,0.08,0.002,404,0.3"
    ]
  end
  let(:csv) { ([ header ] + rows).join("\n") + "\n" }

  def aggregate(output)
    runner = described_class.new(requests: 4, concurrency: 2, timeout: 5)
    allow(described_class).to receive(:available?).and_return(true)
    allow(runner).to receive(:run).and_return(output)
    runner.call(method: "GET", url: "https://example.com/", body: nil)
  end

  describe "#call aggregation" do
    subject(:stats) { aggregate(csv) }

    it "counts the requests" do
      expect(stats[:requests]).to eq(4)
    end

    it "counts responses with codes < 200 or >= 400 as errors" do
      expect(stats[:error_count]).to eq(2)
    end

    it "computes a positive throughput" do
      expect(stats[:rps]).to eq(5.71)
      expect(stats[:rps]).to be > 0
    end

    it "reports latency percentiles in milliseconds" do
      expect(stats[:min_ms]).to eq(100.0)
      expect(stats[:avg_ms]).to eq(250.0)
      expect(stats[:p50_ms]).to eq(300.0)
      expect(stats[:p90_ms]).to eq(400.0)
      expect(stats[:p95_ms]).to eq(400.0)
      expect(stats[:p99_ms]).to eq(400.0)
      expect(stats[:max_ms]).to eq(400.0)
    end

    it "computes the standard deviation in milliseconds" do
      expect(stats[:stddev_ms]).to eq(111.8)
    end

    it "averages the network phase timings in milliseconds" do
      expect(stats[:dns_ms]).to eq(10.0)
      expect(stats[:connect_ms]).to eq(10.0)
      expect(stats[:server_ms]).to eq(65.0)
      expect(stats[:transfer_ms]).to eq(2.0)
    end

    it "tallies the status code distribution" do
      expect(stats[:codes]).to eq(200 => 2, 500 => 1, 404 => 1)
    end

    it "retains a per-request sample for every row" do
      expect(stats[:samples].size).to eq(4)
      expect(stats[:samples].first).to include(seq: 1, response_ms: 100.0, status_code: 200)
    end
  end

  describe "#call with no data rows" do
    it "counts every attempted request as a transport-level error" do
      stats = aggregate("#{header}\n")
      expect(stats[:requests]).to eq(4)
      expect(stats[:error_count]).to eq(4)
      %i[rps min_ms avg_ms p50_ms p90_ms p95_ms p99_ms max_ms
         stddev_ms dns_ms connect_ms server_ms transfer_ms].each do |key|
        expect(stats[key]).to eq(0), "expected #{key} to be 0, got #{stats[key]}"
      end
      expect(stats[:codes]).to eq({})
      expect(stats[:samples]).to eq([])
    end
  end

  describe "#call with fewer rows than requested" do
    it "counts the shortfall as errors while keeping latency stats from survivors" do
      stats = aggregate(([ header ] + rows.first(2)).join("\n") + "\n")
      expect(stats[:requests]).to eq(4)
      expect(stats[:error_count]).to eq(2)
      expect(stats[:min_ms]).to eq(100.0)
      expect(stats[:max_ms]).to eq(200.0)
    end
  end

  describe "#call when hey is missing" do
    it "raises HeyNotAvailable" do
      allow(described_class).to receive(:available?).and_return(false)
      runner = described_class.new(requests: 1, concurrency: 1)
      expect { runner.call(method: "GET", url: "https://example.com/") }
        .to raise_error(described_class::HeyNotAvailable)
    end
  end

  describe ".available?" do
    it "is true when the hey binary is on PATH" do
      allow(described_class).to receive(:`).and_return("/usr/local/bin/hey\n")
      expect(described_class.available?).to be(true)
    end

    it "is false when the binary is absent" do
      allow(described_class).to receive(:`).and_return("")
      expect(described_class.available?).to be(false)
    end
  end

  describe ".version" do
    it "reports the hey version string" do
      allow(described_class).to receive(:`) do |cmd|
        cmd.include?("--version") ? "0.1.5\n" : "/usr/local/bin/hey\n"
      end
      expect(described_class.version).to eq("hey 0.1.5")
    end

    it "is nil when hey is unavailable" do
      allow(described_class).to receive(:`).and_return("")
      expect(described_class.version).to be_nil
    end
  end
end
