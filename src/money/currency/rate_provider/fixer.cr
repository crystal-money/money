require "log"
require "uri"
require "uri/params"
require "http/client"

class Money::Currency
  # [Fixer](https://fixer.io/) currency rate provider.
  class RateProvider::Fixer < RateProvider
    Log = ::Log.for(self)

    property access_key : String do
      ENV["FIXER_ACCESS_KEY"]? ||
        raise "Missing `FIXER_ACCESS_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://data.fixer.io")
    end

    def initialize(*, @access_key = nil, @host = nil)
    end

    # <https://fixer.io/documentation#supportedsymbols>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = URI::Params.encode({
        "access_key": access_key,
      })
      client = HTTP::Client.new(host)
      client.get("/api/symbols?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        currencies =
          result["symbols"].as_h.keys

        currencies
      end
    end

    # <https://fixer.io/documentation#latestrates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = URI::Params.encode({
        "access_key": access_key,
        "base":       base.code,
        "symbols":    target.code,
      })
      client = HTTP::Client.new(host)
      client.get("/api/latest?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "type")}"
        end

        rate =
          result.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
