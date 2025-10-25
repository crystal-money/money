class Money::Currency
  # Currency rate provider that always returns `nil`.
  class RateProvider::Null < RateProvider
    def initialize
    end

    getter base_currency_codes : Array(String) do
      [] of String
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      nil
    end
  end
end
