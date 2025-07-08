require "log"
require "uri"
require "uri/params"
require "http/client"

class Money::Currency
  # [FreeCurrency](https://freecurrencyapi.com/) currency rate provider.
  class RateProvider::Freecurrency < RateProvider
    Log = ::Log.for(self)

    property api_key : String do
      ENV["FREECURRENCY_API_KEY"]? ||
        raise "Missing `FREECURRENCY_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.freecurrencyapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://freecurrencyapi.com/docs/currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = URI::Params.encode({
        "apikey": api_key,
      })
      client = HTTP::Client.new(host)
      client.get("/v1/currencies?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        currencies =
          result["data"].as_h.keys

        currencies
      end
    end

    # <https://freecurrencyapi.com/docs/latest>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = URI::Params.encode({
        "apikey":        api_key,
        "base_currency": base.code,
        "currencies":    target.code,
      })
      client = HTTP::Client.new(host)
      client.get("/v1/latest?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("data", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
