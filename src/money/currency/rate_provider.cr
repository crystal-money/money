struct Money
  class Currency
    abstract class RateProvider
      # Returns an array of supported currency codes.
      abstract def currency_codes : Array(String)

      # Returns the exchange rate between `self` and *other* currency, or `nil` if not found.
      abstract def exchange_rate?(base : Currency, other : Currency) : Rate?
    end
  end
end

require "./rate_provider/*"
