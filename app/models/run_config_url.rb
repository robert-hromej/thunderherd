# frozen_string_literal: true

class RunConfigUrl < ApplicationRecord
  self.primary_key = %i[run_config_id url_id]

  belongs_to :run_config
  belongs_to :url

  validate :url_belongs_to_config_environment

  private

  # A selection from another environment would make runs fire at that other
  # environment's base_url while being guarded/recorded against this config's one.
  def url_belongs_to_config_environment
    return if url.nil? || run_config.nil?
    return if url.environment_id == run_config.environment_id

    errors.add(:url, "must belong to the config's environment")
  end
end
