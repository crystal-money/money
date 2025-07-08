require "log"

class Money::Currency
  # [MoneyMorph](https://moneymorph.dev/) currency rate provider.
  class RateProvider::MoneyMorph < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property host : URI do
      URI.parse("https://moneymorph.dev")
    end

    def initialize(*, @host = nil)
    end

    # <https://moneymorph.dev/#currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      request("/api/currencies") do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result.keys

        currencies
      end
    end

    # <https://moneymorph.dev/#latest>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "base":    base.code,
        "symbols": target.code,
      }
      request("/api/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
