require "log"
require "http/client"

class Money::Currency
  # [Exchange Rate API](https://www.exchangerate-api.com/) currency rate provider.
  class RateProvider::ExchangeRateAPI < RateProvider
    Log = ::Log.for(self)

    property api_key : String do
      ENV["EXCHANGE_RATE_API_KEY"]? ||
        raise "Missing `EXCHANGE_RATE_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://v6.exchangerate-api.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # https://www.exchangerate-api.com/docs/supported-codes-endpoint
    getter currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/v6/#{api_key}/codes") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h["supported_codes"].as_a.map(&.as_a.first.as_s)

        currencies
      end
    end

    # https://www.exchangerate-api.com/docs/pair-conversion-requests
    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get("/v6/#{api_key}/pair/#{base.code}/#{other.code}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)

        unless result.as_h["result"].as_s == "success"
          raise "Rate provider error: #{result.as_h["error-type"]}"
        end

        rate =
          result.as_h["conversion_rate"].to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
