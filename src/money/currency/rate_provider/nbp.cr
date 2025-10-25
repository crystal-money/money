require "log"

class Money::Currency
  # Currency rate provider using data sourced from a daily feed of
  # [Polish National Bank](https://nbp.pl/).
  #
  # NOTE: Supports only `PLN`-targeted conversions.
  class RateProvider::NBP < RateProvider
    include RateProvider::HTTP
    include RateProvider::ManyToOne

    Log = ::Log.for(self)

    def target_currency_code : String
      "PLN"
    end

    getter host : URI do
      URI.parse("https://api.nbp.pl")
    end

    def initialize(*, @host = nil)
    end

    # <https://api.nbp.pl/en.html>
    protected def exchange_rates : Array(Rate)
      Log.debug { "Fetching rates for target currency #{target_currency_code}" }

      params = {
        "format": "json",
      }
      request("/api/exchangerates/tables/a/", params) do |response|
        result = JSON.parse(response.body_io).as_a
        rates = result
          .find!(&.as_h["table"].==("A"))
          .as_h["rates"]
          .as_a

        rates.map do |rate|
          Rate.new(rate["code"].as_s, rate["mid"].to_s.to_big_d)
        end
      end
    end
  end
end
