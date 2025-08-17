require "log"

class Money::Currency
  # [Exchange Rate API](https://www.exchangerate-api.com/) currency rate provider.
  class RateProvider::ExchangeRateAPI < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      option_from_env("EXCHANGE_RATE_API_KEY")
    end
    property host : URI do
      URI.parse("https://v6.exchangerate-api.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://www.exchangerate-api.com/docs/supported-codes-endpoint>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      path =
        "/v6/%s/codes" % URI.encode_path_segment(api_key)

      request(path) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["result"].as_s == "success"
          raise ResponseError.new(result["error-type"])
        end

        currencies =
          result["supported_codes"].as_a.map(&.as_a.first.as_s)

        currencies
      end
    end

    # <https://www.exchangerate-api.com/docs/pair-conversion-requests>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      path =
        "/v6/%s/pair/%s/%s" % {
          URI.encode_path_segment(api_key),
          URI.encode_path_segment(base.code),
          URI.encode_path_segment(target.code),
        }

      request(path) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["result"].as_s == "success"
          raise ResponseError.new(result["error-type"])
        end

        rate =
          result["conversion_rate"].to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
