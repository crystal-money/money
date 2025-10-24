require "log"

class Money::Currency
  # [CoinGecko](https://www.coingecko.com/) currency rate provider.
  class RateProvider::CoinGecko < RateProvider
    include RateProvider::HTTP
    include RateProvider::OneToMany

    Log = ::Log.for(self)

    def base_currency_code : String
      "BTC"
    end

    getter host : URI do
      URI.parse("https://api.coingecko.com")
    end

    def initialize(*, @host = nil)
    end

    # <https://docs.coingecko.com/v3.0.1/reference/exchange-rates>
    protected def exchange_rates : Array(NativeRate)
      Log.debug { "Fetching exchange rates" }

      request("/api/v3/exchange_rates") do |response|
        result = JSON.parse(response.body_io).as_h
        rates =
          result["rates"].as_h

        rates.map do |currency_code, rate|
          NativeRate.new(currency_code.upcase, rate["value"].to_s.to_big_d)
        end
      end
    end
  end
end
