# frozen_string_literal: true

require "rails_helper"

RSpec.describe Environment do
  describe "associations & validations" do
    it "belongs to a site and is valid from the factory" do
      expect(build(:environment)).to be_valid
    end

    it "requires a name" do
      expect(build(:environment, name: nil)).not_to be_valid
    end

    it "enforces name uniqueness scoped to the site" do
      site = create(:site)
      create(:environment, site: site, name: "prod")
      expect(build(:environment, site: site, name: "prod")).not_to be_valid
    end

    it "allows the same name under a different site" do
      create(:environment, name: "prod")
      expect(build(:environment, name: "prod")).to be_valid
    end

    it "requires an http(s) base_url" do
      expect(build(:environment, base_url: "ftp://example.com")).not_to be_valid
      expect(build(:environment, base_url: "https://example.com")).to be_valid
    end
  end

  describe "#label" do
    it "combines the site key and environment name" do
      site = create(:site, key: "acme")
      env = create(:environment, site: site, name: "staging")
      expect(env.label).to eq("acme/staging")
    end
  end

  describe "scopes" do
    it ".production returns only production environments" do
      prod = create(:production_environment)
      create(:environment)
      expect(described_class.production).to contain_exactly(prod)
    end

    it ".staging returns only non-production environments" do
      staging = create(:environment)
      create(:production_environment)
      expect(described_class.staging).to contain_exactly(staging)
    end
  end
end
