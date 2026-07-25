# frozen_string_literal: true

class Machine < ApplicationRecord
  has_many :runs, dependent: :nullify

  validates :fingerprint, presence: true, uniqueness: true

  def label = hostname.presence || fingerprint.first(12)
end
