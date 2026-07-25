# frozen_string_literal: true

require "rails_helper"

RSpec.describe VRunSummary do
  it "exposes one aggregated, read-only row per run" do
    run = create(:run, status: "completed")
    create(:result, run: run, error_count: 3)

    row = described_class.find(run.id)
    expect(row.site).to eq(run.environment.site.key)
    expect(row.env).to eq(run.environment.name)
    expect(row.pages.to_i).to eq(1)
    expect(row.total_errors.to_i).to eq(3)
    expect(row.readonly?).to be(true)
  end

  it "aggregates the dyno formation and latency across a run's results" do
    run = create(:run, status: "completed")
    create(:run_dyno, run: run, process_type: "web", size: "Standard-2X", quantity: 2)
    create(:result, run: run, p95_ms: 100)
    create(:result, run: run, p95_ms: 300)

    row = described_class.find(run.id)
    expect(row.dynos).to eq("web=2:Standard-2X")
    expect(row.avg_p95_ms.to_i).to eq(200)
  end
end
