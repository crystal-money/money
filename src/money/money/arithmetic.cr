struct Money
  module Arithmetic
    # Returns `true` if the money amount is greater than 0, `false` otherwise.
    #
    # ```
    # Money.new(1).positive?  # => true
    # Money.new(0).positive?  # => false
    # Money.new(-1).positive? # => false
    # ```
    def positive?
      amount > 0
    end

    # Returns `true` if the money amount is less than 0, `false` otherwise.
    #
    # ```
    # Money.new(-1).negative? # => true
    # Money.new(0).negative?  # => false
    # Money.new(1).negative?  # => false
    # ```
    def negative?
      amount < 0
    end

    # Returns `true` if the money amount is zero.
    #
    # ```
    # Money.new(0).zero?    # => true
    # Money.new(100).zero?  # => false
    # Money.new(-100).zero? # => false
    # ```
    def zero?
      amount == 0
    end

    # Returns absolute value of `self` as a new `Money` object.
    #
    # ```
    # Money.new(-100).abs # => Money(@amount=1)
    # ```
    def abs : Money
      copy_with(amount: amount.abs)
    end

    # Alias of `#abs`.
    #
    # ```
    # +Money.new(-100) # => Money(@amount=1)
    # ```
    def + : Money
      abs
    end

    # Returns a new `Money` object with changed polarity.
    #
    # ```
    # -Money.new(100) # => Money(@amount=-1)
    # ```
    def - : Money
      copy_with(amount: -amount)
    end

    # Returns a new `Money` object containing the sum of the two
    # operands' monetary values.
    #
    # ```
    # Money.new(100) + Money.new(100) # => Money(@amount=2)
    # ```
    def +(other : Money) : Money
      return self if other.zero?
      with_same_currency(other) do |converted_other|
        copy_with(amount: amount + converted_other.amount)
      end
    end

    # Returns a new `Money` object containing the difference between the two
    # operands' monetary values.
    #
    # ```
    # Money.new(100) - Money.new(99) # => Money(@amount=0.01)
    # ```
    def -(other : Money) : Money
      return self if other.zero?
      with_same_currency(other) do |converted_other|
        copy_with(amount: amount - converted_other.amount)
      end
    end

    # Multiplies the monetary value with the given *other* `Number` and returns
    # a new `Money` object with this monetary value and the same `#currency`.
    #
    # ```
    # Money.new(100) * 2 # => Money(@amount=2)
    # ```
    def *(other : Number) : Money
      copy_with(amount: amount * other)
    end

    # Divides the monetary value with the given *other* `Number` and returns
    # a new `Money` object with this monetary value and the same `#currency`.
    #
    # ```
    # Money.new(100) / 10 # => Money(@amount=0.1)
    # ```
    def /(other : Number) : Money
      copy_with(amount: amount / other)
    end

    # Divides the monetary value with the given *other* `Money` object and
    # returns a ratio.
    #
    # ```
    # Money.new(100) / Money.new(10) # => 10.0
    # ```
    def /(other : Money) : BigDecimal
      with_same_currency(other) do |converted_other|
        amount / converted_other.amount
      end
    end

    # Divide by `Money` or `Number` and return `Tuple` containing
    # quotient and modulus.
    #
    # ```
    # Money.new(100).divmod(9)            # => {Money(@amount=0.11), Money(@amount=0.01)}
    # Money.new(100).divmod(Money.new(9)) # => {11, Money(@amount=0.01)}
    # ```
    def divmod(other : Money) : {BigDecimal, Money}
      with_same_currency(other) do |converted_other|
        quotient, remainder = fractional.divmod(converted_other.fractional)
        {quotient, copy_with(fractional: remainder)}
      end
    end

    # :ditto:
    def divmod(other : Number) : {Money, Money}
      quotient, remainder = fractional.divmod(other.to_big_i)
      {copy_with(fractional: quotient), copy_with(fractional: remainder)}
    end

    # Equivalent to `#divmod(other)[1]`.
    #
    # ```
    # Money.new(100).modulo(9)            # => Money(@amount=0.01)
    # Money.new(100).modulo(Money.new(9)) # => Money(@amount=0.01)
    # ```
    def modulo(other) : Money
      divmod(other)[1]
    end

    # Alias of `#modulo`.
    def %(other) : Money
      modulo(other)
    end

    # If different signs `#modulo(other) - other`, otherwise `#modulo(other)`.
    #
    # ```
    # Money.new(100).remainder(9) # => Money(@amount=0.01)
    # ```
    def remainder(other : Number) : Money
      if (amount < 0 && other < 0) || (amount > 0 && other > 0)
        modulo(other)
      else
        modulo(other) - copy_with(amount: other)
      end
    end

    # Rounds the monetary amount to smallest unit of coinage, using
    # rounding *mode* if given, or `Money.rounding_mode` otherwise.
    #
    # ```
    # Money.new(10.1, "USD").round                   # => Money(@amount=10, @currency="USD")
    # Money.new(10.5, "USD").round(mode: :ties_even) # => Money(@amount=10, @currency="USD")
    # Money.new(10.5, "USD").round(mode: :ties_away) # => Money(@amount=11, @currency="USD")
    # ```
    def round(precision : Int = 0, mode : Number::RoundingMode = Money.rounding_mode) : Money
      copy_with(amount: @amount.round(precision, mode: mode))
    end
  end
end
