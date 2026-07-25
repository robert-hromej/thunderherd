# frozen_string_literal: true

# A deployed version of the target app, captured so a run knows what code it measured.
class AppDeploy < ApplicationRecord
  belongs_to :environment
  has_many :runs, foreign_key: :deploy_id, dependent: :nullify, inverse_of: :deploy

  validates :heroku_release, uniqueness: { scope: :environment_id }, allow_nil: true

  def label = [ heroku_release, git_sha&.first(7) ].compact.join(" ")
end
