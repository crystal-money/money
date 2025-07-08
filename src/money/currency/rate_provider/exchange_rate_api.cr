require "log"

class Money::Currency
  # [Exchange Rate API](https://www.exchangerate-api.com/) currency rate provider.
  class RateProvider::ExchangeRateAPI < RateProvider
    include RateProvider::HTTP

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

    # <https://www.exchangerate-api.com/docs/supported-codes-endpoint>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      request("/v6/#{api_key}/codes") do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result["supported_codes"].as_a.map(&.as_a.first.as_s)

        currencies
      end
    end

    # <https://www.exchangerate-api.com/docs/pair-conversion-requests>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      request("/v6/#{api_key}/pair/#{base.code}/#{target.code}") do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["result"].as_s == "success"
          raise "Rate provider error: #{result["error-type"]}"
        end

        rate =
          result["conversion_rate"].to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
