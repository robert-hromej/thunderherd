class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # thunderherd generates HTTP load against whatever hosts you configure and has no
  # user model. Setting THUNDERHERD_HTTP_USER locks the whole app (UI + API) behind
  # one shared credential; leaving it unset keeps local development frictionless.
  # The check reads the environment per request so it can be exercised in specs.
  # See README "Security".
  before_action :authenticate_shared_credential, if: -> { ENV["THUNDERHERD_HTTP_USER"].present? }

  private

  def authenticate_shared_credential
    authenticate_or_request_with_http_basic("thunderherd") do |user, password|
      # `&`, not `&&`: compare both halves every time so the response time does not
      # reveal whether the username alone was right.
      secure_equal?(user, ENV["THUNDERHERD_HTTP_USER"]) & secure_equal?(password, ENV["THUNDERHERD_HTTP_PASSWORD"])
    end
  end

  def secure_equal?(given, expected)
    ActiveSupport::SecurityUtils.secure_compare(given.to_s, expected.to_s)
  end
end
