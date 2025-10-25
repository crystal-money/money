require "log"

class Money::Currency
  # [Exchangerate](https://exchangerate.host/) currency rate provider.
  class RateProvider::Exchangerate < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    getter access_key : String do
      option_from_env("EXCHANGERATE_ACCESS_KEY")
    end
    getter host : URI do
      URI.parse("https://api.exchangerate.host")
    end

    def initialize(*, @access_key = nil, @host = nil)
    end

    # <https://exchangerate.host/documentation#supported_currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "access_key": access_key,
      }
      request("/list", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise ResponseError.new(
            result.dig("error", "code"),
            result.dig?("error", "info"))
        end

        currencies =
          result["currencies"].as_h.keys

        currencies
      end
    end

    # <https://exchangerate.host/documentation#real_time_rates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "access_key": access_key,
        "source":     base.code,
        "currencies": target.code,
      }
      request("/live", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise ResponseError.new(
            result.dig("error", "code"),
            result.dig?("error", "info"))
        end

        rate =
          result.dig("quotes", "%s%s" % {base.code, target.code}).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
