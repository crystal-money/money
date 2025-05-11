struct Money
  abstract class Bank
    # An exchange `Currency::RateStore` object, used to persist exchange rate pairs.
    property store : Currency::RateStore { Money.default_rate_store }

    def initialize(@store = nil)
    end

    # Exchanges the given `Money` object to a new `Money` object in
    # *to* `Currency`.
    abstract def exchange(from : Money, to : Currency) : Money
  end
end

require "./bank/*"
