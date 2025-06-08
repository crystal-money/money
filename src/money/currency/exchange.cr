class Money::Currency
  class Exchange
    # An exchange `RateStore` object, used to persist exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_store` if set to `nil` (the default).
    property store : RateStore?

    # :ditto:
    def store : RateStore
      @store || Money.default_rate_store
    end

    # An exchange `RateProvider` object, used to fetch exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_provider` if set to `nil` (the default).
    property provider : RateProvider?

    # :ditto:
    def provider : RateProvider
      @provider || Money.default_rate_provider
    end

    def initialize(@store = nil, @provider = nil)
    end

    # Returns an array of supported (registered) currencies.
    def currencies : Array(Currency)
      provider.currency_codes.compact_map do |code|
        Currency.find?(code)
      end
    end

    # Exchanges the given `Money` object to a new `Money` object in
    # *to* `Currency`.
    def exchange(from : Money, to : Currency) : Money
      amount =
        from.amount * exchange_rate(from.currency, to)

      Money.new(amount: amount, currency: to, exchange: self)
    end

    # Returns the exchange rate between *base* and *other* currency,
    # or `nil` if not found.
    def exchange_rate?(base : Currency, other : Currency) : BigDecimal?
      return 1.to_big_d if base == other

      store[base, other]? ||
        update_rate(base, other)
    end

    # Returns the exchange rate between *base* and *other* currency,
    # or raises `UnknownRateError` if not found.
    def exchange_rate(base : Currency, other : Currency) : BigDecimal
      exchange_rate?(base, other) ||
        raise UnknownRateError.new("No conversion rate known for #{base} -> #{other}")
    end

    private def update_rate(base : Currency, other : Currency) : BigDecimal?
      if rate = provider.exchange_rate?(base, other)
        store << rate
        rate.value
      end
    end
  end
end

require "./exchange/*"
