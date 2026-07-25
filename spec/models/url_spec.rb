# frozen_string_literal: true

require "rails_helper"

RSpec.describe Url do
  describe "constant" do
    it "lists the supported HTTP methods" do
      expect(Url::METHODS).to eq(%w[GET POST PUT PATCH DELETE HEAD])
    end
  end

  describe "validations" do
    it "is valid from the factory" do
      expect(build(:url)).to be_valid
    end

    it "rejects an unknown method" do
      url = build(:url)
      url[:method] = "TRACE"
      expect(url).not_to be_valid
    end

    it "requires a path" do
      expect(build(:url, path: nil)).not_to be_valid
    end
  end

  describe "#full_url" do
    it "joins base_url and path" do
      env = create(:environment, base_url: "https://example.com")
      url = create(:url, environment: env, path: "/checkout")
      expect(url.full_url).to eq("https://example.com/checkout")
    end

    it "normalizes a trailing slash on the base and a missing leading slash on the path" do
      env = create(:environment, base_url: "https://example.com/")
      url = create(:url, environment: env, path: "checkout")
      expect(url.full_url).to eq("https://example.com/checkout")
    end
  end

  describe ".active scope" do
    it "returns only active urls" do
      active = create(:url, is_active: true)
      create(:url, is_active: false)
      expect(described_class.active).to contain_exactly(active)
    end
  end
end
