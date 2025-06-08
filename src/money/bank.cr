struct Money
  class Bank
    # An exchange `Currency::RateStore` object, used to persist exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_store` if set to `nil` (the default).
    property store : Currency::RateStore?

    # :ditto:
    def store : Currency::RateStore
      @store || Money.default_rate_store
    end

    # An exchange `Currency::RateProvider` object, used to fetch exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_provider` if set to `nil` (the default).
    property provider : Currency::RateProvider?

    # :ditto:
    def provider : Currency::RateProvider
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

      Money.new(amount: amount, currency: to, bank: self)
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

require "./bank/*"
