require "log"

class Money::Currency
  # [BitPay](https://www.bitpay.com/) currency rate provider.
  #
  # NOTE: Supports only some of the crypto-based conversions.
  class RateProvider::BitPay < RateProvider
    include RateProvider::HTTP
    include RateProvider::OneToMany

    Log = ::Log.for(self)

    # Supported values: `BTC`, `BCH`, `ETH`, `XRP`, `DOGE`, `LTC`.
    #
    # See <https://www.bitpay.com/exchange-rates>
    getter base_currency_code : String = "BTC"

    getter host : URI do
      URI.parse("https://bitpay.com")
    end

    def initialize(*, @base_currency_code = "BTC", @host = nil)
    end

    # <https://developer.bitpay.com/reference/retrieve-all-the-rates-for-a-given-cryptocurrency>
    protected def exchange_rates : Array(Rate)
      Log.debug { "Fetching rates for base currency #{base_currency_code}" }

      request("/api/rates/%s" % base_currency_code) do |response|
        result = JSON.parse(response.body_io).as_a
        result.map do |rate|
          Rate.new(rate["code"].as_s, rate["rate"].to_s.to_big_d)
        end
      end
    end
  end
end
