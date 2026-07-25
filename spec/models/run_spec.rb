# frozen_string_literal: true

require "rails_helper"

RSpec.describe Run do
  describe "validations" do
    it "is valid from the factory" do
      expect(build(:run)).to be_valid
    end

    it "rejects an unknown status" do
      expect(build(:run, status: "paused")).not_to be_valid
    end

    it "requires positive integer requests_per_url and concurrency" do
      expect(build(:run, requests_per_url: 0)).not_to be_valid
      expect(build(:run, concurrency: -1)).not_to be_valid
    end
  end

  describe "#duration_s" do
    it "returns the rounded difference in seconds" do
      t = Time.current
      run = build(:run, started_at: t, finished_at: t + 5.53)
      expect(run.duration_s).to eq(5.5)
    end

    it "is nil while the run has not finished" do
      expect(build(:running_run, started_at: Time.current, finished_at: nil).duration_s).to be_nil
    end
  end

  describe "#dyno_formation" do
    it "renders the dynos ordered by process_type" do
      run = create(:run)
      create(:run_dyno, run: run, process_type: "web", quantity: 2, size: "Standard-2X")
      create(:run_dyno, run: run, process_type: "worker", quantity: 1, size: "Standard-1X")
      expect(run.dyno_formation).to eq("web=2:Standard-2X worker=1:Standard-1X")
    end
  end

  describe "scopes" do
    it ".completed returns only completed runs" do
      completed = create(:run, status: "completed")
      create(:running_run)
      expect(described_class.completed).to contain_exactly(completed)
    end

    it ".recent orders by started_at descending" do
      older = create(:run, started_at: 2.days.ago)
      newer = create(:run, started_at: 1.hour.ago)
      expect(described_class.recent.to_a).to eq([ newer, older ])
    end
  end
end
