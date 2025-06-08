class Money::Currency
  class RateProvider::Null < RateProvider
    def currency_codes : Array(String)
      [] of String
    end

    def exchange_rate?(base : Currency, other : Currency) : Rate?
      nil
    end
  end
end
