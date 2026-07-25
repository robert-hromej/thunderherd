# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SPA shell", type: :request do
  # A missing/renamed entrypoint makes ViteRuby raise, which is exactly the
  # white-screen failure this guards against.
  it "serves the app shell with a built Vite bundle at the root" do
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="root"')
    expect(response.body).to match(%r{<script[^>]+/vite[^"]*/assets/application-[^"]+\.js})
  end

  it "serves the same shell for client-side routes so deep links work" do
    get "/runs/42"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="root"')
  end

  it "leaves the health check to its own controller" do
    get "/up"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('id="root"')
  end
end

RSpec.describe "shared-credential gate", type: :request do
  USER_ENV = "THUNDERHERD_HTTP_USER"
  PASSWORD_ENV = "THUNDERHERD_HTTP_PASSWORD"

  around do |example|
    previous = ENV.values_at(USER_ENV, PASSWORD_ENV)
    ENV[USER_ENV] = "admin"
    ENV[PASSWORD_ENV] = "s3cret"
    example.run
  ensure
    ENV[USER_ENV], ENV[PASSWORD_ENV] = previous
  end

  def basic(user, password)
    { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  end

  it "challenges unauthenticated requests once a credential is configured" do
    get "/api/runs"
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a wrong password" do
    get "/api/runs", headers: basic("admin", "nope")
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a wrong user" do
    get "/api/runs", headers: basic("someone", "s3cret")
    expect(response).to have_http_status(:unauthorized)
  end

  it "lets the configured credential through" do
    get "/api/runs", headers: basic("admin", "s3cret")
    expect(response).to have_http_status(:ok)
  end

  it "is off entirely when no credential is configured" do
    ENV.delete(USER_ENV)
    get "/api/runs"
    expect(response).to have_http_status(:ok)
  end
end
