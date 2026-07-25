# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadTest::Executor, "network capture" do
  let(:fake_runner) do
    Class.new do
      def initialize(**); end

      def call(method:, url:, body: nil)
        { requests: 2, error_count: 0, rps: 1.0, min_ms: 10, avg_ms: 20, p50_ms: 20,
          p90_ms: 25, p95_ms: 30, p99_ms: 30, max_ms: 30, stddev_ms: 5, dns_ms: 1,
          connect_ms: 2, server_ms: 15, transfer_ms: 1, codes: { 200 => 2 }, samples: [] }
      end
    end
  end

  let(:environment) { create(:environment, base_url: "https://staging.example.com") }

  before do
    create(:url, environment: environment)
    allow(HostInfo).to receive_messages(
      machine_attrs: { fingerprint: "fp-net", hostname: "h", os: "o", arch: "a",
                       cpu_model: "c", cpu_cores: 1, ram_mb: 1 },
      operator_attrs: { name: "Net Op", email: "net@example.com" }
    )
    allow(Infra::Heroku).to receive_messages(dyno_formation: [], latest_release: nil)
  end

  it "stores the network context with the run, passing the target host" do
    expect(NetworkInfo).to receive(:collect).with(target_host: "staging.example.com")
      .and_return({ kind: "wifi", rtt_ms: 12.5, isp: "Test ISP", measured_at: Time.current })

    run = described_class.new(environment: environment, requests_per_url: 2,
                              concurrency: 1, runner_class: fake_runner).call

    expect(run.run_network).to be_present
    expect(run.run_network.kind).to eq("wifi")
    expect(run.run_network.rtt_ms).to eq(12.5)
    expect(run.run_network.isp).to eq("Test ISP")
  end

  it "does not fail the run when network capture blows up" do
    allow(NetworkInfo).to receive(:collect).and_raise("no network")

    run = described_class.new(environment: environment, requests_per_url: 2,
                              concurrency: 1, runner_class: fake_runner).call

    expect(run.status).to eq("completed")
    expect(run.run_network).to be_nil
  end
end
