# frozen_string_literal: true

class Site < ApplicationRecord
  has_many :environments, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
end
