# frozen_string_literal: true

require "rails_helper"

RSpec.describe Machine do
  describe "validations" do
    it "requires a unique fingerprint" do
      create(:machine, fingerprint: "fp-1")
      expect(build(:machine, fingerprint: "fp-1")).not_to be_valid
      expect(build(:machine, fingerprint: nil)).not_to be_valid
    end
  end

  describe "#label" do
    it "prefers the hostname" do
      expect(build(:machine, hostname: "laptop").label).to eq("laptop")
    end

    it "falls back to the first 12 chars of the fingerprint" do
      machine = build(:machine, hostname: nil, fingerprint: "abcdefghijklmnop")
      expect(machine.label).to eq("abcdefghijkl")
    end
  end
end
