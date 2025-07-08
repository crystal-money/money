require "log"

class Money::Currency
  # [Fixer](https://fixer.io/) currency rate provider.
  class RateProvider::Fixer < RateProvider
    include RateProvider::HTTP

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

      params = {
        "access_key": access_key,
      }
      request("/api/symbols", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "type")}"
        end

        currencies =
          result["symbols"].as_h.keys

        currencies
      end
    end

    # <https://fixer.io/documentation#latestrates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "access_key": access_key,
        "base":       base.code,
        "symbols":    target.code,
      }
      request("/api/latest", params) do |response|
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
