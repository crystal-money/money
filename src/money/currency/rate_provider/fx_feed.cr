require "log"

class Money::Currency
  # [FXFeed](https://fxfeed.io/) currency rate provider.
  class RateProvider::FXFeed < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      option_from_env("FXFEED_API_KEY")
    end
    property host : URI do
      URI.parse("https://api.fxfeed.io")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://fxfeed.io/docs#latest-currency-data>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "api_key": api_key,
      }
      request("/v1/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"]?.try(&.as_bool)
          raise ResponseError.new(
            result.dig("error", "code"),
            result.dig?("error", "message"))
        end

        currencies =
          result["rates"].as_h.keys

        currencies
      end
    end

    # <https://fxfeed.io/docs#latest-currency-data>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "api_key":    api_key,
        "base":       base.code,
        "currencies": target.code,
      }
      request("/v1/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"]?.try(&.as_bool)
          raise ResponseError.new(
            result.dig("error", "code"),
            result.dig?("error", "message"))
        end

        rate =
          result.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
