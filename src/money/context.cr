struct Money
  # `Context` class holding global settings for `Money` objects.
  # Each `Fiber` has its own `Fiber#money_context` instance.
  #
  # See also `Money.spawn_with_same_context`.
  class Context
    # :nodoc:
    module Delegators
      # Alias of `Fiber.current.money_context`.
      @[AlwaysInline]
      def context : Context
        Fiber.current.money_context
      end

      # Alias of `Fiber.current.money_context=`.
      @[AlwaysInline]
      def context=(context : Context)
        Fiber.current.money_context = context
      end

      delegate \
        :infinite_precision?, :infinite_precision=,
        :rounding_mode, :rounding_mode=,
        :default_currency, :default_currency=,
        :default_exchange, :default_exchange=,
        :default_rate_store, :default_rate_store=,
        :default_rate_provider, :default_rate_provider=,
        to: context
    end

    # Use this to control infinite precision cents.
    property? infinite_precision : Bool = false

    # Default rounding mode.
    property rounding_mode : Number::RoundingMode = :ties_even

    # Default currency for creating new `Money` object.
    property default_currency : Currency { Currency.find("USD") }

    # :ditto:
    def default_currency=(currency_code : String | Symbol)
      self.default_currency = Currency.find(currency_code)
    end

    # Each `Money` object is associated to a currency exchange object.
    # This property allows you to specify the default exchange object.
    # The default value for this property is an instance of
    # `Currency::Exchange`, which allows one to specify custom exchange rates.
    property default_exchange : Currency::Exchange do
      Currency::Exchange.new
    end

    # Default currency rate store used by `Currency::Exchange` objects.
    # It defaults to using an in-memory, concurrency-safe, store instance for
    # storing exchange rates.
    property default_rate_store : Currency::RateStore do
      Currency::RateStore::Memory.new
    end

    # Default currency rate provider used by `Currency::Exchange` objects.
    property default_rate_provider : Currency::RateProvider do
      Currency::RateProvider::Null.new
    end
  end
end
