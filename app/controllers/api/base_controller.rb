# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    include RunSerialization

    # Raised by controllers for request-level input problems; rendered as 422 JSON.
    class UnprocessableError < StandardError; end

    # Keep real CSRF protection (inherited default): the SPA sends the token via the
    # X-CSRF-Token header (csrf_meta_tags + axios), so cross-site POSTs are rejected.
    # In the test environment Rails disables forgery protection, so specs need no token.

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
    rescue_from ActiveRecord::RecordNotDestroyed, with: :render_not_destroyed
    rescue_from UnprocessableError, with: :render_unprocessable

    private

    def render_not_found(error)
      render json: { error: error.message }, status: :not_found
    end

    def render_invalid(error)
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def render_not_destroyed(error)
      messages = error.record&.errors&.full_messages.presence || [ error.message ]
      render json: { errors: messages }, status: :unprocessable_entity
    end

    def render_unprocessable(error)
      render json: { errors: [ error.message ] }, status: :unprocessable_entity
    end
  end
end
