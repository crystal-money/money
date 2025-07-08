require "log"

class Money::Currency
  # [MetalpriceAPI](https://metalpriceapi.com/) currency rate provider.
  class RateProvider::MetalpriceAPI < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      ENV["METALPRICE_API_KEY"]? ||
        raise "Missing `METALPRICE_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.metalpriceapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://metalpriceapi.com/documentation#api_symbol>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "api_key": api_key,
      }
      request("/v1/symbols", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "statusCode")}"
        end

        currencies =
          result["symbols"].as_h.keys

        currencies
      end
    end

    # <https://metalpriceapi.com/documentation#api_realtime>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "api_key":    api_key,
        "base":       base.code,
        "currencies": target.code,
      }
      request("/v1/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "statusCode")}"
        end

        rate =
          result.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
