struct Money
  module Constructors
    # Creates a new `Money` object of value given in the *unit* of the given
    # *currency*.
    #
    # ```
    # Money.from_amount(23.45, "USD") # => Money(@amount=23.45 @currency="USD")
    # Money.from_amount(23.45, "JPY") # => Money(@amount=23.0 @currency="JPY")
    # ```
    #
    # See also `#initialize`.
    def from_amount(amount : Number | String, currency = default_currency, exchange = nil) : Money
      new(amount.to_big_d, currency, exchange)
    end

    # Creates a new `Money` object with value `0`.
    #
    # ```
    # Money.zero       # => Money(@amount=0.0)
    # Money.zero(:pln) # => Money(@amount=0.0 @currency="PLN")
    # ```
    def zero(currency = default_currency, exchange = nil) : Money
      new(0, currency, exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # American dollar currency.
    #
    # ```
    # Money.us_dollar(100) # => Money(@amount=1.0 @currency="USD")
    # ```
    def us_dollar(cents, exchange = nil)
      new(cents, "USD", exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # Euro currency.
    #
    # ```
    # Money.euro(100) # => Money(@amount=1.0 @currency="EUR")
    # ```
    def euro(cents, exchange = nil)
      new(cents, "EUR", exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # Bitcoin cryptocurrency.
    #
    # ```
    # Money.bitcoin(100) # => Money(@amount=0.000001 @currency="BTC")
    # ```
    def bitcoin(cents, exchange = nil)
      new(cents, "BTC", exchange)
    end
  end
end
