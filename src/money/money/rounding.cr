struct Money
  module Rounding
    # Returns the nearest possible amount in cash value (cents).
    #
    # For example, in Swiss franc (CHF), the smallest possible amount of
    # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
    # and for CHF 0.08, CHF 0.10.
    #
    # See also `#rounded_to_nearest_cash_value` and `Currency#smallest_denomination`.
    protected def nearest_cash_value(rounding_mode : Number::RoundingMode = Money.rounding_mode) : BigDecimal?
      return unless smallest_denomination = currency.smallest_denomination

      rounded_value =
        (fractional / smallest_denomination).round(rounding_mode)
      rounded_value *= smallest_denomination
      rounded_value
    end

    # Returns a new `Money` instance with the nearest possible amount in cash value
    # (cents), or `nil` if the `#currency` has no smallest denomination defined.
    #
    # For example, in Swiss franc (CHF), the smallest possible amount of
    # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
    # and for CHF 0.08, CHF 0.10.
    #
    # ```
    # Money.new(0.07, "CHF").rounded_to_nearest_cash_value? # => Money(@amount = 0.05)
    # Money.new(0.08, "CHF").rounded_to_nearest_cash_value? # => Money(@amount = 0.1)
    # Money.new(10.0, "XAG").rounded_to_nearest_cash_value? # nil
    # ```
    def rounded_to_nearest_cash_value?(rounding_mode : Number::RoundingMode = Money.rounding_mode) : Money?
      if nearest_cash_value = nearest_cash_value(rounding_mode)
        copy_with(fractional: nearest_cash_value)
      end
    end

    # :ditto:
    #
    # NOTE: This variant raises `UndefinedSmallestDenominationError` if
    # `#rounded_to_nearest_cash_value?` returns `nil`.
    def rounded_to_nearest_cash_value!(rounding_mode : Number::RoundingMode = Money.rounding_mode) : Money
      rounded_to_nearest_cash_value?(rounding_mode) ||
        raise UndefinedSmallestDenominationError.new(currency)
    end

    # :ditto:
    #
    # NOTE: This variant returns `self` if `#rounded_to_nearest_cash_value?`
    # returns `nil`.
    def rounded_to_nearest_cash_value(rounding_mode : Number::RoundingMode = Money.rounding_mode) : Money
      rounded_to_nearest_cash_value?(rounding_mode) || self
    end

    # Rounds the monetary amount to smallest unit of coinage, using
    # rounding *mode* if given, or `Money.rounding_mode` otherwise.
    #
    # ```
    # Money.new(10.1, "USD").round                   # => Money(@amount=10.0, @currency="USD")
    # Money.new(10.5, "USD").round(mode: :ties_even) # => Money(@amount=10.0, @currency="USD")
    # Money.new(10.5, "USD").round(mode: :ties_away) # => Money(@amount=11.0, @currency="USD")
    # ```
    def round(precision : Int = 0, mode : Number::RoundingMode = Money.rounding_mode) : Money
      copy_with(amount: @amount.round(precision, mode: mode))
    end
  end
end
