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
    protected def target_exchange_rates : Array(Rate)
      Log.debug { "Fetching rates for base currency #{base_currency_code}" }

      path =
        "/api/rates/%s" % URI.encode_path_segment(base_currency_code)

      request(path) do |response|
        result = JSON.parse(response.body_io).as_a
        rates =
          result.map do |rate|
            Rate.new(base_currency_code, rate["code"].as_s, rate["rate"].to_s.to_big_d)
          end

        rates
      end
    end
  end
end
