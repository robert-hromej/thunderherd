# frozen_string_literal: true

module Api
  class AppDeploysController < BaseController
    def index
      counts = Run.group(:deploy_id).count
      deploys = AppDeploy.includes(environment: :site).order(created_at: :desc).map do |d|
        { id: d.id, environment: d.environment.label, heroku_release: d.heroku_release,
          git_sha: d.git_sha, deployed_at: d.deployed_at, description: d.description,
          runs_count: counts.fetch(d.id, 0) }
      end
      render json: deploys
    end
  end
end
