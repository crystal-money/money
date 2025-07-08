require "log"
require "uri"
require "uri/params"
require "http/client"

class Money::Currency
  # [Abstract API](https://www.abstractapi.com/api/exchange-rate-api) currency rate provider.
  class RateProvider::AbstractAPI < RateProvider
    Log = ::Log.for(self)

    property api_key : String do
      ENV["ABSTRACT_API_KEY"]? ||
        raise "Missing `ABSTRACT_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://exchange-rates.abstractapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://docs.abstractapi.com/exchange-rates/live>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = URI::Params.encode({
        "api_key": api_key,
        "base":    "USD",
      })
      client = HTTP::Client.new(host)
      client.get("/v1/live/?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        currencies =
          result["exchange_rates"].as_h.keys

        currencies
      end
    end

    # <https://docs.abstractapi.com/exchange-rates/live>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = URI::Params.encode({
        "api_key": api_key,
        "base":    base.code,
        "target":  target.code,
      })
      client = HTTP::Client.new(host)
      client.get("/v1/live/?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("exchange_rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
