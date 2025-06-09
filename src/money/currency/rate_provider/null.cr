class Money::Currency
  class RateProvider::Null < RateProvider
    getter currency_codes : Array(String) do
      [] of String
    end

    def exchange_rate?(base : Currency, other : Currency) : Rate?
      nil
    end
  end
end
