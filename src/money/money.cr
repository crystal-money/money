require "./money/allocate"
require "./money/arithmetic"
require "./money/casting"
require "./money/constructors"
require "./money/exchange"
require "./money/formatting"
require "./money/parse"
require "./money/rounding"

# "Money is any object or record that is generally accepted as payment for
# goods and services and repayment of debts in a given socio-economic context
# or country." - [Wikipedia](https://en.wikipedia.org/wiki/Money)
#
# An instance of `Money` represents an amount of a specific currency.
#
# `Money` is a value object and should be treated as immutable.
struct Money
  extend Money::Context::Delegators

  extend Money::Constructors
  extend Money::Parse

  include Money::Casting
  include Money::Arithmetic
  include Money::Allocate
  include Money::Formatting
  include Money::Rounding
  include Money::Exchange

  include Comparable(Money)
  include Steppable

  # Yields the given block with the current `Money.context` as an argument.
  #
  # ```
  # Money.configure do |context|
  #   context.infinite_precision = true
  #   context.default_currency = "EUR"
  # end
  # ```
  def self.configure(& : Money::Context ->) : Nil
    yield context
  end

  # Spawns a new fiber with the `Money::Context` copied from the current fiber.
  #
  # ```
  # Money.default_currency.code # => "USD"
  # Money.default_currency = "PLN"
  #
  # spawn do
  #   Money.default_currency.code # => "USD"
  # end
  #
  # # vs
  #
  # Money.spawn_with_same_context do
  #   Money.default_currency.code # => "PLN"
  # end
  # ```
  #
  # NOTE: References to the `#default_{currency, exchange, rate_store}` properties
  # will be shared between the current fiber and the spawned fiber.
  def self.spawn_with_same_context(**options, &block : ->) : Nil
    current_context = context.dup
    wrapper = -> do
      self.context = current_context
      block.call
    end
    spawn(*Tuple.new, **options, &wrapper)
  end

  # Sets the given infinite precision value within the lifetime of the given block.
  #
  # See also `Money.infinite_precision?`.
  def self.with_infinite_precision(enabled = true, &)
    prev_infinite_precision = infinite_precision?
    self.infinite_precision = enabled
    begin
      yield
    ensure
      self.infinite_precision = prev_infinite_precision
    end
  end

  # Sets the given rounding *mode* within the lifetime of the given block.
  #
  # See also `Money.rounding_mode`.
  def self.with_rounding_mode(mode : Number::RoundingMode, &)
    prev_rounding_mode = rounding_mode
    self.rounding_mode = mode
    begin
      yield
    ensure
      self.rounding_mode = prev_rounding_mode
    end
  end

  # Disallows currency conversion within the lifetime of the given block.
  #
  # See also `Money.disallow_currency_conversion!`.
  def self.without_currency_conversion(&)
    prev_exchange = default_exchange
    disallow_currency_conversion!
    begin
      yield
    ensure
      self.default_exchange = prev_exchange
    end
  end

  # Sets the default exchange to be a `Currency::Exchange::SingleCurrency` exchange that raises
  # on currency exchange. Useful when apps operate in a single currency at a time.
  def self.disallow_currency_conversion!
    self.default_exchange = Currency::Exchange::SingleCurrency.new
  end

  # Creates a new `Money` object of *value* given as an fractional amount
  # of the given *currency*.
  #
  # ```
  # Money.new(0, "USD")    # => Money(@amount=0.0 @currency="USD")
  # Money.new(1_50, "USD") # => Money(@amount=1.5 @currency="USD")
  # ```
  def self.new(value : Int = 0, currency = Money.default_currency)
    new(
      fractional: value,
      currency: currency,
    )
  end

  # Creates a new `Money` object of *value* given as an whole amount
  # of the given *currency*.
  #
  # ```
  # Money.new(1.5, "USD")          # => Money(@amount=1.5 @currency="USD")
  # Money.new(1.5.to_big_d, "USD") # => Money(@amount=1.5 @currency="USD")
  # ```
  #
  # WARNING: Floating points cannot guarantee precision. Therefore, they
  # should only be used when you no longer need to represent currency or
  # working with another system that requires floats.
  def self.new(value : Number, currency = Money.default_currency)
    new(
      amount: value,
      currency: currency,
    )
  end

  # Numerical value of the money.
  getter amount : BigDecimal

  # The money's currency.
  getter currency : Currency

  # Creates a new `Money` object of value given as an *amount*
  # of the given *currency*.
  #
  # ```
  # Money.new(amount: 13.37) # => Money(@amount=13.37)
  # ```
  def initialize(*, amount : Number, currency = Money.default_currency)
    @currency = Currency[currency]
    @amount = amount.to_big_d
  end

  # Creates a new `Money` object of value given as a *fractional*
  # of the given *currency*.
  #
  # ```
  # Money.new(fractional: 13_37) # => Money(@amount=13.37)
  # ```
  def initialize(*, fractional : Number, currency = Money.default_currency)
    @currency = Currency[currency]
    @amount = fractional.to_big_d / @currency.subunit_to_unit
  end

  # Returns a new `Money` instance with same `currency` property set
  # as in `self`.
  protected def copy_with(**options) : Money
    options =
      {currency: @currency}.merge(options)

    Money.new(**options)
  end

  def_equals_and_hash amount, currency

  # Compares two `Money` objects. Returns `0` if the two objects are equal,
  # a negative number if this object is considered less than *other* or
  # a positive number if this object is considered greater than *other*.
  #
  # NOTE: Two `Money` objects with `0` amount are considered equal,
  # regardless of their currency.
  #
  # NOTE: Performs currency conversion if necessary.
  def <=>(other : Money) : Int32
    return 0 if zero? && other.zero?

    with_same_currency(other) do |converted_other|
      amount <=> converted_other.amount
    end
  end

  # Compares two `Money` objects. Returns `true` if `self` is equal to *other*,
  # `false` otherwise.
  #
  # NOTE: Two `Money` objects with `0` amount are considered equal,
  # regardless of their currency.
  #
  # NOTE: Performs currency conversion if necessary.
  def =~(other : Money) : Bool
    (self <=> other).zero?
  end

  # Returns a new `Money` instance with incremented `fractional` value.
  #
  # ```
  # Money.new(1_00, "USD").succ # => Money(@amount=1.01 @currency="USD")
  # Money.new(1, "JPY").succ    # => Money(@amount=2.0 @currency="JPY")
  # ```
  def succ : Money
    copy_with(fractional: fractional + 1)
  end

  # Returns a new `Money` instance in a given currency - if it's different
  # from the current `#currency` - or `self` otherwise, leaving the amount
  # intact and **not** performing currency conversion.
  def with_currency(new_currency : String | Symbol | Currency) : Money
    new_currency = Currency[new_currency]
    if new_currency == currency
      self
    else
      copy_with(currency: new_currency, amount: @amount)
    end
  end

  # Returns the numerical value of the money.
  #
  # ```
  # Money.new(1_00, "USD").amount # => 1.0
  # ```
  #
  # See also `#fractional`, `Money.infinite_precision?` and `Money.rounding_mode`.
  def amount : BigDecimal
    if Money.infinite_precision?
      @amount
    else
      @amount.round(currency.exponent, mode: Money.rounding_mode)
    end
  end

  # The value of the monetary amount represented in the fractional or subunit
  # of the currency.
  #
  # For example, in the US dollar currency the fractional unit is cents, and
  # there are 100 cents in one US dollar. So given the `Money` representation of
  # one US dollar, the fractional interpretation is 100.
  #
  # Another example is that of the Kuwaiti dinar. In this case the fractional
  # unit is the fils and there 1000 fils to one Kuwaiti dinar. So given the
  # `Money` representation of one Kuwaiti dinar, the fractional interpretation
  # is 1000.
  #
  # See also `Money.infinite_precision?` and `Money.rounding_mode`.
  def fractional : BigDecimal
    amount * currency.subunit_to_unit
  end

  # Alias of `#fractional`.
  @[AlwaysInline]
  def cents : BigDecimal
    fractional
  end
end

require "./money/json"
require "./money/yaml"
