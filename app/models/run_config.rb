# frozen_string_literal: true

class RunConfig < ApplicationRecord
  belongs_to :environment
  has_many :run_config_urls, dependent: :destroy
  has_many :urls, through: :run_config_urls
  has_many :runs, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :requests_per_url, :concurrency, :timeout_s,
            numericality: { only_integer: true, greater_than: 0 }

  # URLs to hit: the active part of an explicit selection, else every active URL
  # in the environment. is_active is the per-URL kill switch — deactivating a URL
  # must stop selected configs from hitting it too (an all-inactive selection
  # yields no URLs rather than silently widening to the whole environment).
  def target_urls
    selected = urls.to_a
    return environment.urls.active.to_a if selected.empty?

    selected.select(&:is_active)
  end
end
