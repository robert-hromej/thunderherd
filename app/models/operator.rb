# frozen_string_literal: true

class Operator < ApplicationRecord
  has_many :runs, dependent: :nullify

  validates :name, presence: true
  validates :email, uniqueness: true, allow_nil: true
end
