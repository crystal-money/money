require "log"

class Money::Currency
  # [Coinbase](https://www.coinbase.com/) currency rate provider.
  class RateProvider::Coinbase < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    getter host : URI do
      URI.parse("https://api.coinbase.com")
    end

    def initialize(*, @host = nil)
    end

    getter base_currency_codes : Array(String) do
      fiat_currency_codes + crypto_currency_codes
    end

    # <https://docs.cdp.coinbase.com/coinbase-app/track-apis/currencies#get-fiat-currencies>
    protected def fiat_currency_codes : Array(String)
      fetch_currency_codes "fiat", "/v2/currencies", "id"
    end

    # <https://docs.cdp.coinbase.com/coinbase-app/track-apis/currencies#get-cryptocurrencies>
    protected def crypto_currency_codes : Array(String)
      fetch_currency_codes "crypto", "/v2/currencies/crypto", "code"
    end

    private def fetch_currency_codes(type : String, path : String, prop : String) : Array(String)
      Log.debug { "Fetching supported #{type} currencies" }

      request(path) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result["data"].as_a.map(&.as_h[prop].as_s)

        currencies
      end
    end

    # <https://docs.cdp.coinbase.com/coinbase-app/track-apis/exchange-rates#data-api-exchange-rates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "currency": base.code,
      }
      request("/v2/exchange-rates", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("data", "rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
