class Money
  # Exchange ?
  abstract class Bank
    # It defaults to using an in-memory, thread safe store instance for
    # storing exchange rates.
    class_property default_store : Currency::RateStore { Currency::RateStore::Memory.new }

    # An exchange `Currency::RateStore` object, used to persist exchange rate pairs.
    def store
      Bank.default_store
    end

    # Exchanges the given `Money` object to a new `Money` object in
    # *to* `Currency`.
    abstract def exchange(from : Money, to : Currency) : Money
  end
end

require "./bank/*"
