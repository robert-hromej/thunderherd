# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppDeploy do
  describe "#label" do
    it "combines the release and the short git sha" do
      deploy = build(:app_deploy, heroku_release: "v42", git_sha: "abc1234def")
      expect(deploy.label).to eq("v42 abc1234")
    end

    it "uses only the release when there is no git sha" do
      deploy = build(:app_deploy, heroku_release: "v42", git_sha: nil)
      expect(deploy.label).to eq("v42")
    end

    it "uses only the short git sha when there is no release" do
      deploy = build(:app_deploy, heroku_release: nil, git_sha: "deadbeef99")
      expect(deploy.label).to eq("deadbee")
    end
  end

  describe "validations" do
    it "enforces heroku_release uniqueness per environment but allows nil" do
      env = create(:environment)
      create(:app_deploy, environment: env, heroku_release: "v1")
      expect(build(:app_deploy, environment: env, heroku_release: "v1")).not_to be_valid
      expect(build(:app_deploy, environment: env, heroku_release: nil)).to be_valid
    end
  end
end
