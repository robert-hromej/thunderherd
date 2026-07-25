# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadTest::UrlListImporter do
  let(:environment) { create(:environment) }
  subject(:importer) { described_class.new(environment: environment) }

  describe "#parse" do
    it "defaults to GET when no method is given" do
      expect(importer.parse("https://example.com/a")).to eq([ "GET", "https://example.com/a", nil ])
    end

    it "extracts an explicit method case-insensitively" do
      method, url, = importer.parse("post https://example.com/a")
      expect(method).to eq("POST")
      expect(url).to eq("https://example.com/a")
    end

    it "parses a JSON body after the pipe separator" do
      method, url, body = importer.parse('POST https://example.com/a | {"x":1}')
      expect(method).to eq("POST")
      expect(url).to eq("https://example.com/a")
      expect(body).to eq("x" => 1)
    end
  end

  describe "#import_lines" do
    it "creates a url per line and skips blanks and comments" do
      result = importer.import_lines([
        "GET https://example.com/home",
        "",
        "# a comment",
        'POST https://example.com/checkout | {"qty":2}'
      ])

      expect(result.created).to eq(2)
      expect(result.updated).to eq(0)
      expect(environment.urls.pluck(:path)).to contain_exactly("/home", "/checkout")

      checkout = environment.urls.find_by(path: "/checkout")
      expect(checkout[:method]).to eq("POST")
      expect(checkout.body).to eq("qty" => 2)
    end

    it "uses the request path from the url" do
      importer.import_lines([ "GET https://example.com/search?q=box" ])
      expect(environment.urls.pluck(:path)).to eq([ "/search?q=box" ])
    end

    it "is idempotent — a second import updates rather than creates" do
      lines = [ "GET https://example.com/home" ]
      importer.import_lines(lines)
      result = importer.import_lines(lines)
      expect(result.created).to eq(0)
      expect(result.updated).to eq(1)
      expect(environment.urls.count).to eq(1)
    end

    it "returns a Data result exposing created and updated" do
      result = importer.import_lines([ "GET https://example.com/x" ])
      expect(result).to respond_to(:created, :updated)
    end

    it "imports bare path lines without crashing" do
      result = importer.import_lines([ "GET /products", "status" ])
      expect(result.created).to eq(2)
      expect(environment.urls.pluck(:path)).to contain_exactly("/products", "/status")
    end

    it "skips lines pointing at a foreign host instead of merging them" do
      result = importer.import_lines([ "https://example.com/", "https://www.iana.org/" ])
      expect(result.created).to eq(1)
      expect(result.skipped).to eq(1)
      expect(environment.urls.pluck(:path)).to eq([ "/" ])
    end
  end
end
