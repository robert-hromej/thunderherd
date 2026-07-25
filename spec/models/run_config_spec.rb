# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunConfig do
  describe "validations" do
    it "is valid from the factory" do
      expect(build(:run_config)).to be_valid
    end

    it "requires a unique name" do
      create(:run_config, name: "nightly")
      expect(build(:run_config, name: "nightly")).not_to be_valid
    end

    it "requires positive integer numeric settings" do
      expect(build(:run_config, requests_per_url: 0)).not_to be_valid
      expect(build(:run_config, concurrency: 0)).not_to be_valid
      expect(build(:run_config, timeout_s: 0)).not_to be_valid
    end
  end

  describe "#target_urls" do
    it "returns the explicitly selected urls when present" do
      env = create(:environment)
      config = create(:run_config, environment: env)
      selected = create(:url, environment: env)
      create(:url, environment: env)
      config.urls << selected
      expect(config.target_urls).to contain_exactly(selected)
    end

    it "falls back to every active url in the environment" do
      env = create(:environment)
      config = create(:run_config, environment: env)
      active = create(:url, environment: env, is_active: true)
      create(:url, environment: env, is_active: false)
      expect(config.target_urls).to contain_exactly(active)
    end
  end
end
