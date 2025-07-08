require "./money/allocate"
require "./money/arithmetic"
require "./money/casting"
require "./money/constructors"
require "./money/exchange"
require "./money/formatting"
require "./money/parse"

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
  include Money::Exchange

  include Comparable(Money)
  include Steppable

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

  # Sets the default exchange to be a `Currency::Exchange::SingleCurrency` exchange that raises
  # on currency exchange. Useful when apps operate in a single currency at a time.
  def self.disallow_currency_conversion!
    self.default_exchange = Currency::Exchange::SingleCurrency.new
  end

  # Numerical value of the money.
  getter amount : BigDecimal

  # The money's currency.
  getter currency : Currency

  # The `Currency::Exchange` object which currency exchanges are performed with.
  #
  # NOTE: Will return `Money.default_exchange` if set to `nil` (the default).
  property exchange : Currency::Exchange?

  # :ditto:
  def exchange : Currency::Exchange
    @exchange || Money.default_exchange
  end

  # Creates a new `Money` object of value given as an *amount*
  # of the given *currency* (as fractional if `Int`, or whole amount otherwise).
  #
  # ```
  # Money.new                      # => Money(@amount=0.0 @currency="USD")
  # Money.new(1_50)                # => Money(@amount=1.5 @currency="USD")
  # Money.new(1.5, :usd)           # => Money(@amount=1.5 @currency="USD")
  # Money.new(1.5.to_big_d, "USD") # => Money(@amount=1.5 @currency="USD")
  # ```
  def initialize(amount : Number = 0, currency = Money.default_currency, exchange = nil)
    initialize(amount, currency, exchange)
  end

  # :nodoc:
  def initialize(amount : BigDecimal | BigRational, currency, exchange)
    @currency = Currency.wrap(currency)
    @amount = amount.to_big_d
    @exchange = exchange
  end

  # :nodoc:
  def initialize(amount : Float, currency, exchange)
    unless amount.finite?
      raise ArgumentError.new "Must be initialized with a finite value"
    end
    initialize(amount.to_big_d, currency, exchange)
  end

  # :nodoc:
  def initialize(*, fractional : BigDecimal, currency = Money.default_currency, exchange = nil)
    @currency = Currency.wrap(currency)
    @amount = fractional / @currency.subunit_to_unit
    @exchange = exchange
  end

  # :nodoc:
  def initialize(fractional : Int, currency, exchange)
    initialize(
      fractional: fractional.to_big_d,
      currency: currency,
      exchange: exchange,
    )
  end

  # Returns a new `Money` instance with same `currency` and `exchange`
  # properties set as in `self`.
  protected def copy_with(**options) : Money
    options = {currency: currency, exchange: exchange}.merge(options)
    Money.new(**options)
  end

  # Returns hash value based on the `amount` and `currency` attributes.
  def_hash amount, currency

  # Returns `true` if the two `Money` objects have same `#amount` and `#currency`,
  # `false` otherwise.
  #
  # NOTE: Unlike `#==` it does **not** perform currency conversion.
  def eql?(other : Money) : Bool
    hash == other.hash
  end

  # Compares two `Money` objects.
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

  # Returns a new `Money` instance in a given currency - if it's different
  # from the current `#currency` - or `self` otherwise, leaving the amount
  # intact and **not** performing currency conversion.
  def with_currency(new_currency : String | Symbol | Currency) : Money
    new_currency = Currency.wrap(new_currency)
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

  # Returns the nearest possible amount in cash value (cents).
  #
  # For example, in Swiss franc (CHF), the smallest possible amount of
  # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
  # and for CHF 0.08, CHF 0.10.
  #
  # See also `#rounded_to_nearest_cash_value` and `Currency#smallest_denomination`.
  def nearest_cash_value(rounding_mode : Number::RoundingMode = Money.rounding_mode) : BigDecimal
    unless smallest_denomination = currency.smallest_denomination
      raise UndefinedSmallestDenominationError.new(currency)
    end
    rounded_value =
      (fractional / smallest_denomination).round(rounding_mode)
    rounded_value *= smallest_denomination
    rounded_value
  end

  # Returns a new `Money` instance with the nearest possible amount in cash value.
  #
  # See also `#nearest_cash_value`.
  def rounded_to_nearest_cash_value(rounding_mode : Number::RoundingMode = Money.rounding_mode) : Money
    copy_with(fractional: nearest_cash_value(rounding_mode))
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

require "./money/json"
