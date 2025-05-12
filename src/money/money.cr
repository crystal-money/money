require "./money/context"
require "./money/allocate"
require "./money/arithmetic"
require "./money/casting"
require "./money/constructors"
require "./money/exchange"
require "./money/formatting"
require "./money/parse"

# "Money is any object or record that is generally accepted as payment for
# goods and services and repayment of debts in a given socio-economic context
# or country." - [Wikipedia](http://en.wikipedia.org/wiki/Money)
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

  # Sets the given rounding *mode* within the scope of the given block
  def self.with_rounding_mode(mode : Number::RoundingMode, &)
    prev_rounding_mode = rounding_mode
    self.rounding_mode = mode
    begin
      yield
    ensure
      self.rounding_mode = prev_rounding_mode
    end
  end

  # Sets the default bank to be a `Bank::SingleCurrency` bank that raises on
  # currency exchange. Useful when apps operate in a single currency at a time.
  def self.disallow_currency_conversion!
    self.default_bank = Bank::SingleCurrency.new
  end

  # Numerical value of the money.
  getter amount : BigDecimal

  # The money's currency.
  getter currency : Currency

  # The `Bank` object which currency exchanges are performed with.
  #
  # NOTE: Setting `nil` (the default) will delegate to `Money.default_bank`.
  property bank : Bank?

  # :ditto:
  def bank : Bank
    @bank || Money.default_bank
  end

  # Creates a new `Money` object of value given as an *amount*
  # of the given *currency* (as fractional if `Int`, or whole amount otherwise)
  #
  # ```
  # Money.new                      # => Money(@amount=0 @currency="USD")
  # Money.new(1_50)                # => Money(@amount=1.5 @currency="USD")
  # Money.new(1.5, :usd)           # => Money(@amount=1.5 @currency="USD")
  # Money.new(1.5.to_big_d, "USD") # => Money(@amount=1.5 @currency="USD")
  # ```
  def initialize(amount : Number = 0, currency = Money.default_currency, bank = nil)
    initialize(amount, currency, bank)
  end

  # :nodoc:
  def initialize(amount : BigDecimal | BigRational, currency, bank)
    @currency = Currency.wrap(currency)
    @amount = amount.to_big_d
    @bank = bank
  end

  # :nodoc:
  def initialize(amount : Float, currency, bank)
    unless amount.finite?
      raise ArgumentError.new "Must be initialized with a finite value"
    end
    initialize(amount.to_big_d, currency, bank)
  end

  # :nodoc:
  def initialize(*, fractional : BigDecimal, currency = Money.default_currency, bank = nil)
    @currency = Currency.wrap(currency)
    @amount = fractional / @currency.subunit_to_unit
    @bank = bank
  end

  # :nodoc:
  def initialize(fractional : Int, currency, bank)
    initialize(
      fractional: fractional.to_big_d,
      currency: currency,
      bank: bank,
    )
  end

  # Returns a new `Money` instance with same `currency` and `bank`
  # properties set as in `self`.
  protected def copy_with(**options) : Money
    options = {currency: currency, bank: bank}.merge(options)
    Money.new(**options)
  end

  # Returns hash value based on the `amount` and `currency` attributes.
  def_hash amount, currency

  # Compares two `Money` objects.
  def <=>(other : Money) : Int32
    return 0 if zero? && other.zero?
    with_same_currency(other) do |converted_other|
      amount <=> converted_other.amount
    end
  end

  # Returns the numerical value of the money.
  #
  # ```
  # Money.new(1_00, "USD").amount # => 1.0
  # ```
  #
  # See `#to_big_d` and `#fractional`, also `Money.rounding_mode`.
  def amount : BigDecimal
    return @amount if Money.infinite_precision?
    @amount.round(currency.exponent, mode: Money.rounding_mode)
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
  def fractional : BigDecimal
    amount * currency.subunit_to_unit
  end

  # Alias of `#amount`.
  def dollars : BigDecimal
    amount
  end

  # Alias of `#fractional`.
  def cents : BigDecimal
    fractional
  end

  # Returns the nearest possible amount in cash value (cents).
  #
  # For example, in Swiss franc (CHF), the smallest possible amount of
  # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
  # and for CHF 0.08, CHF 0.10.
  #
  # See `Currency#smallest_denomination`, also `Money.rounding_mode`.
  def nearest_cash_value : BigDecimal
    unless smallest_denomination = currency.smallest_denomination
      raise UndefinedSmallestDenominationError.new
    end
    rounded_value =
      (fractional / smallest_denomination).round(mode: Money.rounding_mode)
    rounded_value *= smallest_denomination
    rounded_value
  end

  # See `#nearest_cash_value`.
  def rounded_to_nearest_cash_value : Money
    copy_with(fractional: nearest_cash_value)
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

require "./money/json"
