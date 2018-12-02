require "big"

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
      fractional > 0
    end

    # Returns `true` if the money amount is less than 0, `false` otherwise.
    #
    # ```
    # Money.new(-1).negative? # => true
    # Money.new(0).negative?  # => false
    # Money.new(1).negative?  # => false
    # ```
    def negative?
      fractional < 0
    end

    # Returns `true` if the money amount is zero.
    #
    # ```
    # Money.new(0).zero?    # => true
    # Money.new(100).zero?  # => false
    # Money.new(-100).zero? # => false
    # ```
    def zero?
      fractional == 0
    end

    # Returns absolute value of `self` as a new `Money` object.
    #
    # ```
    # Money.new(-100).abs # => #<Money @fractional=100>
    # ```
    def abs : Money
      Money.new(fractional.abs, currency)
    end

    # Alias of `#abs`.
    #
    # ```
    # +Money.new(-100) # => #<Money @fractional=100>
    # ```
    def + : Money
      abs
    end

    # Returns a new `Money` object with changed polarity.
    #
    # ```
    # -Money.new(100) # => #<Money @fractional=-100>
    # ```
    def - : Money
      Money.new(-fractional, currency)
    end

    # Returns a new `Money` object containing the sum of the two
    # operands' monetary values.
    #
    # ```
    # Money.new(100) + Money.new(100) # => #<Money @fractional=200>
    # ```
    def +(other : Money) : Money
      return self if other.zero?
      with_same_currency(other) do |converted_other|
        Money.new(fractional + converted_other.fractional, currency)
      end
    end

    # Returns a new `Money` object containing the difference between the two
    # operands' monetary values.
    #
    # ```
    # Money.new(100) - Money.new(99) # => #<Money @fractional=1>
    # ```
    def -(other : Money) : Money
      return self if other.zero?
      with_same_currency(other) do |converted_other|
        Money.new(fractional - converted_other.fractional, currency)
      end
    end

    # Multiplies the monetary value with the given *other* `Number` and returns
    # a new `Money` object with this monetary value and the same `#currency`.
    #
    # ```
    # Money.new(100) * 2 # => #<Money @fractional=200>
    # ```
    def *(other : Number) : Money
      new_amount = (fractional * other).to_i
      Money.new(new_amount, currency)
    end

    # Divides the monetary value with the given *other* `Number` and returns
    # a new `Money` object with this monetary value and the same `#currency`.
    #
    # ```
    # Money.new(100) / 10 # => #<Money @fractional=10>
    # ```
    def /(other : Number) : Money
      new_amount = fractional.to_big_d / other.to_big_d
      Money.new(new_amount, currency)
    end

    # Divides the monetary value with the given *other* `Money` object and
    # returns a ratio.
    #
    # ```
    # Money.new(100) / Money.new(10) # => 10.0
    # ```
    def /(other : Money) : Float64
      with_same_currency(other) do |converted_other|
        fractional.to_f / converted_other.fractional.to_f
      end
    end

    # Divide by `Money` or `Number` and return `Tuple` containing
    # quotient and modulus.
    #
    # ```
    # Money.new(100).divmod(9)            # => {#<Money @fractional=11>, #<Money @fractional=1>}
    # Money.new(100).divmod(Money.new(9)) # => {11, #<Money @fractional=1>}
    # ```
    def divmod(other : Money) : {Int64, Money}
      with_same_currency(other) do |converted_other|
        quotient, remainder = fractional.divmod(converted_other.fractional)
        {quotient, Money.new(remainder, currency)}
      end
    end

    # ditto
    def divmod(other : Number) : {Money, Money}
      quotient, remainder = fractional.divmod(other.to_i)
      {Money.new(quotient, currency), Money.new(remainder, currency)}
    end

    # Equivalent to `#divmod(other)[1]`.
    #
    # ```
    # Money.new(100).modulo(9)            # => #<Money @fractional=1>
    # Money.new(100).modulo(Money.new(9)) # => #<Money @fractional=1>
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
    # Money.new(100).remainder(9) # => #<Money @fractional=1>
    # ```
    def remainder(other : Number) : Money
      if (fractional < 0 && other < 0) || (fractional > 0 && other > 0)
        modulo(other)
      else
        modulo(other) - Money.new(other, currency)
      end
    end
  end
end
