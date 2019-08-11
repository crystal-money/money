struct Money
  module Constructors
    # Creates a new `Money` object of value given in the *unit* of the given
    # *currency*.
    #
    # ```
    # Money.from_amount(23.45, "USD") # => Money(@amount=23.45 @currency="USD")
    # Money.from_amount(23.45, "JPY") # => Money(@amount=23 @currency="JPY")
    # ```
    #
    # See `#initialize`.
    def from_amount(amount : Number | String, currency = default_currency) : Money
      new(amount.to_big_d, currency)
    end

    # Creates a new `Money` object with value `0`.
    #
    # ```
    # Money.zero       # => Money(@amount=0)
    # Money.zero(:pln) # => Money(@amount=0 @currency="PLN")
    # ```
    def zero(currency = default_currency) : Money
      new(0, currency)
    end

    # Creates a new `Money` object of the given value, using the
    # American dollar currency.
    #
    # ```
    # Money.us_dollar(100) # => Money(@amount=1 @currency="USD")
    # ```
    def us_dollar(cents)
      new(cents, "USD")
    end

    # Creates a new `Money` object of the given value, using the
    # Euro currency.
    #
    # ```
    # Money.euro(100) # => Money(@amount=1 @currency="EUR")
    # ```
    def euro(cents)
      new(cents, "EUR")
    end

    # Creates a new `Money` object of the given value, using the
    # Bitcoin cryptocurrency.
    #
    # ```
    # Money.bitcoin(100) # => Money(@amount=0.000001 @currency="BTC")
    # ```
    def bitcoin(cents)
      new(cents, "BTC")
    end
  end
end
