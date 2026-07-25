# frozen_string_literal: true

class Environment < ApplicationRecord
  belongs_to :site
  has_many :urls, dependent: :destroy
  has_many :run_configs, dependent: :destroy
  has_many :app_deploys, dependent: :destroy
  has_many :runs, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :base_url, presence: true, format: { with: %r{\Ahttps?://\S+\z}i }

  scope :production, -> { where(is_production: true) }
  scope :staging, -> { where(is_production: false) }

  def label = "#{site.key}/#{name}"
end
