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
    def from_amount(amount : Number | String, currency = Money.default_currency, exchange = nil) : Money
      new(
        amount: amount.to_big_d,
        currency: currency,
        exchange: exchange,
      )
    end

    # Creates a new `Money` object of value given in the fractional *unit* of
    # the given *currency*.
    #
    # ```
    # Money.from_fractional(23_45.67, "USD") # => Money(@amount=23.4567 @currency="USD")
    # Money.from_fractional(23_45, "USD")    # => Money(@amount=23.45 @currency="USD")
    # ```
    #
    # See also `#initialize`.
    def from_fractional(fractional : Number | String, currency = Money.default_currency, exchange = nil) : Money
      new(
        fractional: fractional.to_big_d,
        currency: currency,
        exchange: exchange,
      )
    end

    # Creates a new `Money` object with value `0`.
    #
    # ```
    # Money.zero       # => Money(@amount=0.0)
    # Money.zero(:pln) # => Money(@amount=0.0 @currency="PLN")
    # ```
    def zero(currency = Money.default_currency, exchange = nil) : Money
      new(0, currency, exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # American dollar currency.
    #
    # ```
    # Money.us_dollar(1_00) # => Money(@amount=1.0 @currency="USD")
    # ```
    def us_dollar(value, exchange = nil) : Money
      new(value, "USD", exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # Euro currency.
    #
    # ```
    # Money.euro(1_00) # => Money(@amount=1.0 @currency="EUR")
    # ```
    def euro(value, exchange = nil) : Money
      new(value, "EUR", exchange)
    end

    # Creates a new `Money` object of the given value, using the
    # Bitcoin cryptocurrency.
    #
    # ```
    # Money.bitcoin(100) # => Money(@amount=0.000001 @currency="BTC")
    # ```
    def bitcoin(value, exchange = nil) : Money
      new(value, "BTC", exchange)
    end
  end
end
