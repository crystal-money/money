require "log"
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

    # https://docs.abstractapi.com/exchange-rates/live
    property currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/v1/live/?api_key=#{api_key}&base=USD") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h["exchange_rates"].as_h.keys

        currencies
      end
    end

    # https://docs.abstractapi.com/exchange-rates/live
    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get(
        "/v1/live/?api_key=#{api_key}&base=#{base.code}&target=#{other.code}"
      ) do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        rate =
          result.as_h.dig("exchange_rates", other.code).to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
