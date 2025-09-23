class Money::Currency
  class Exchange
    # An exchange `RateStore` object, used to persist exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_store` if set to `nil` (the default).
    if_defined?(:JSON) { @[JSON::Field(converter: Money::Currency::RateStore::Converter)] }
    if_defined?(:YAML) { @[YAML::Field(converter: Money::Currency::RateStore::Converter)] }
    property rate_store : RateStore?

    # :ditto:
    def rate_store : RateStore
      @rate_store || Money.default_rate_store
    end

    # An exchange `RateProvider` object, used to fetch exchange rate pairs.
    #
    # NOTE: Will return `Money.default_rate_provider` if set to `nil` (the default).
    if_defined?(:JSON) { @[JSON::Field(converter: Money::Currency::RateProvider::Converter)] }
    if_defined?(:YAML) { @[YAML::Field(converter: Money::Currency::RateProvider::Converter)] }
    property rate_provider : RateProvider?

    # :ditto:
    def rate_provider : RateProvider
      @rate_provider || Money.default_rate_provider
    end

    # A concurrency-safe mutex used to synchronize access to the
    # `#rate_store` and `#rate_provider` objects.
    if_defined?(:JSON) { @[JSON::Field(ignore: true)] }
    if_defined?(:YAML) { @[YAML::Field(ignore: true)] }
    @mutex = Mutex.new

    def initialize(@rate_store = nil, @rate_provider = nil)
    end

    # Returns an array of supported (registered) base currencies.
    def base_currencies : Array(Currency)
      currency_codes = @mutex.synchronize { rate_provider.base_currency_codes }
      currency_codes.compact_map do |code|
        Currency.find?(code)
      end
    end

    # Returns an array of supported (registered) target currencies.
    def target_currencies : Array(Currency)
      currency_codes = @mutex.synchronize { rate_provider.target_currency_codes }
      currency_codes.compact_map do |code|
        Currency.find?(code)
      end
    end

    # Exchanges the given `Money` object to a new `Money` object in
    # *to* `Currency`.
    def exchange(from : Money, to : String | Symbol | Currency) : Money
      amount =
        from.amount * exchange_rate(from.currency, to)

      Money.new(amount: amount, currency: to)
    end

    # Returns the exchange rate between *base* and *target* currency,
    # or `nil` if not found.
    def exchange_rate?(base : String | Symbol | Currency, target : String | Symbol | Currency) : BigDecimal?
      base, target =
        Currency[base], Currency[target]

      return 1.to_big_d if base == target

      @mutex.synchronize do
        rate_store[base, target]? ||
          update_rate(base, target)
      end
    end

    # Returns the exchange rate between *base* and *target* currency,
    # or raises `UnknownRateError` if not found.
    def exchange_rate(base : String | Symbol | Currency, target : String | Symbol | Currency) : BigDecimal
      exchange_rate?(base, target) ||
        raise UnknownRateError.new(base, target)
    end

    private def update_rate(base : Currency, target : Currency) : BigDecimal?
      return unless rate_provider.supports_currency_pair?(base, target)

      if rate = rate_provider.exchange_rate?(base, target)
        rate_store << rate
        rate.value
      end
    end
  end
end

require "./exchange/*"
