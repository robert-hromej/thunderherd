# frozen_string_literal: true

class Url < ApplicationRecord
  METHODS = %w[GET POST PUT PATCH DELETE HEAD].freeze

  belongs_to :environment
  has_many :results, dependent: :nullify

  validates :method, inclusion: { in: METHODS }
  validates :path, presence: true

  scope :active, -> { where(is_active: true) }

  def full_url
    base = environment.base_url.chomp("/")
    p = path.start_with?("/") ? path : "/#{path}"
    "#{base}#{p}"
  end
end
