struct Money
  abstract class Bank
    # An exchange `Currency::RateStore` object, used to persist exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_store` if set to `nil` (the default).
    property store : Currency::RateStore?

    # :ditto:
    def store : Currency::RateStore
      @store || Money.default_rate_store
    end

    def initialize(@store = nil)
    end

    # Returns the exchange rate between `self` and *other* currency, or `nil` if not found.
    def exchange_rate?(base : Currency, other : Currency) : BigDecimal?
      base == other ? 1.to_big_d : store[base, other]?
    end

    # Returns the exchange rate between `self` and *other* currency or raises
    # `UnknownRateError` if not found.
    def exchange_rate(base : Currency, other : Currency) : BigDecimal
      base == other ? 1.to_big_d : store[base, other]
    end

    # Exchanges the given `Money` object to a new `Money` object in
    # *to* `Currency`.
    abstract def exchange(from : Money, to : Currency) : Money
  end
end

require "./bank/*"
