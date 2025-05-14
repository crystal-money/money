struct Money
  # `Context` class holding global settings for `Money` objects.
  # Each `Fiber` has its own `Fiber#money_context` instance.
  #
  # See also `Money.same_context_wrapper` and `Money.spawn_with_same_context`.
  class Context
    # :nodoc:
    module Delegators
      delegate \
        :infinite_precision?, :infinite_precision=,
        :rounding_mode, :rounding_mode=,
        :default_currency, :default_currency=,
        :default_bank, :default_bank=,
        :default_rate_store, :default_rate_store=,
        to: Fiber.current.money_context
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

    # Each `Money` object is associated to a bank object, which is responsible
    # for currency exchange. This property allows you to specify the default
    # bank object. The default value for this property is an instance of
    # `Bank::VariableExchange`, which allows one to specify custom exchange rates.
    property default_bank : Bank { Bank::VariableExchange.new }

    # Default currency rate store used by `Bank` objects. It defaults to using an
    # in-memory, concurrency-safe, store instance for storing exchange rates.
    property default_rate_store : Currency::RateStore { Currency::RateStore::Memory.new }
  end
end
