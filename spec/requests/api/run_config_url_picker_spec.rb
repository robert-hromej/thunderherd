# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api run-config URL subset", type: :request do
  let(:environment) { create(:environment) }
  let!(:url_a) { create(:url, environment: environment, path: "/a") }
  let!(:url_b) { create(:url, environment: environment, path: "/b") }
  let!(:url_c) { create(:url, environment: environment, path: "/c") }

  it "creates a config targeting a subset of URLs" do
    post "/api/run_configs", params: {
      run_config: { name: "subset", environment_id: environment.id,
                    requests_per_url: 5, concurrency: 2, url_ids: [ url_a.id, url_b.id ] }
    }
    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["url_ids"]).to contain_exactly(url_a.id, url_b.id)
    expect(body["target_urls_count"]).to eq(2)

    config = RunConfig.find(body["id"])
    expect(config.target_urls.map(&:path)).to contain_exactly("/a", "/b")
  end

  it "ignores URL ids from other environments" do
    foreign = create(:url)
    post "/api/run_configs", params: {
      run_config: { name: "clean", environment_id: environment.id, url_ids: [ url_a.id, foreign.id ] }
    }
    expect(response.parsed_body["url_ids"]).to eq([ url_a.id ])
  end

  it "clears the subset with [] (falls back to all active URLs)" do
    config = create(:run_config, environment: environment)
    config.run_config_urls.create!(url_id: url_a.id)

    patch "/api/run_configs/#{config.id}", params: { run_config: { url_ids: [] } }
    expect(response.parsed_body["url_ids"]).to eq([])
    expect(config.reload.target_urls.size).to eq(3)
  end

  it "leaves the subset untouched when url_ids is absent" do
    config = create(:run_config, environment: environment)
    config.run_config_urls.create!(url_id: url_c.id)

    patch "/api/run_configs/#{config.id}", params: { run_config: { concurrency: 4 } }
    expect(config.reload.run_config_urls.pluck(:url_id)).to eq([ url_c.id ])
  end
end
