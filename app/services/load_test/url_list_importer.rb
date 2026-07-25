# frozen_string_literal: true

require "uri"
require "json"

module LoadTest
  # Imports a plain URL-list file into an Environment's URLs.
  # Line format: "[METHOD] url [| json-body]"; blank lines and #comments ignored.
  # Absolute URLs pointing at a different host than the environment's base_url are
  # skipped (imported paths always resolve against the environment's own host).
  class UrlListImporter
    Result = Data.define(:created, :updated, :skipped)

    def initialize(environment:)
      @environment = environment
    end

    def import(path)
      import_lines(File.readlines(path, chomp: true))
    end

    def import_lines(lines)
      created = 0
      updated = 0
      skipped = 0
      ActiveRecord::Base.transaction do
        lines.each do |line|
          next if line.strip.empty? || line.strip.start_with?("#")

          method, url, body = parse(line)
          request_path = path_for(url)
          if request_path.nil?
            skipped += 1
            next
          end

          record = @environment.urls.find_or_initialize_by(method: method, path: request_path)
          record.new_record? ? (created += 1) : (updated += 1)
          record.body = body
          record.save!
        end
      end
      Result.new(created:, updated:, skipped:)
    end

    def parse(line)
      method = "GET"
      rest = line.strip
      if (m = rest.match(/\A(#{Url::METHODS.join('|')})\s+/i))
        method = m[1].upcase
        rest = rest[m[0].length..]
      end
      url, body = rest.split("|", 2).map(&:strip)
      [ method, url, body.present? ? JSON.parse(body) : nil ]
    end

    private

    # Returns the request path for a line, or nil when the line targets a foreign
    # host (silently merging e.g. https://other.example/ into the environment's "/"
    # would load-test the wrong thing). Bare paths ("/products") are taken as-is —
    # URI::Generic has no #request_uri, which used to crash the import midway.
    def path_for(raw_url)
      return nil if raw_url.blank?

      uri = URI.parse(raw_url)
      if uri.host
        return nil if environment_host && uri.host != environment_host

        uri.respond_to?(:request_uri) ? uri.request_uri : normalize_path(uri.path)
      else
        normalize_path(raw_url)
      end
    rescue URI::InvalidURIError
      nil
    end

    def normalize_path(path)
      path.start_with?("/") ? path : "/#{path}"
    end

    def environment_host
      return @environment_host if defined?(@environment_host)

      @environment_host = begin
        URI.parse(@environment.base_url).host
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
