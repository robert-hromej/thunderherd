# frozen_string_literal: true

require "rails_helper"

RSpec.describe Site do
  it "is valid from the factory" do
    expect(build(:site)).to be_valid
  end

  it "requires a unique key and a name" do
    create(:site, key: "acme")
    expect(build(:site, key: "acme")).not_to be_valid
    expect(build(:site, name: nil)).not_to be_valid
  end

  it "refuses destruction while environments exist" do
    site = create(:environment).site
    expect(site.destroy).to be(false)
    expect(site.errors[:base]).to be_present
  end
end
