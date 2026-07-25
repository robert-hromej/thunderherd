# frozen_string_literal: true

require "rails_helper"

RSpec.describe Result do
  describe "validations" do
    it "is valid from the factory" do
      expect(build(:result)).to be_valid
    end

    it "rejects an unknown method" do
      result = build(:result)
      result[:method] = "TRACE"
      expect(result).not_to be_valid
    end

    it "requires a non-negative integer request count" do
      expect(build(:result, requests: -1)).not_to be_valid
    end
  end

  describe ".completed_runs" do
    it "returns only results attached to completed runs" do
      completed = create(:result, run: create(:run, status: "completed"))
      create(:result, run: create(:running_run))
      expect(described_class.completed_runs).to contain_exactly(completed)
    end
  end

  describe "error_rate generated column" do
    it "is computed by the database from error_count / requests" do
      result = create(:result, requests: 100, error_count: 5)
      expect(result.reload.error_rate.to_f).to eq(0.05)
    end
  end
end
