require "./money/*"

# "Money is any object or record that is generally accepted as payment for
# goods and services and repayment of debts in a given socio-economic context
# or country." - [Wikipedia](http://en.wikipedia.org/wiki/Money)
#
# An instance of `Money` represents an amount of a specific currency.
#
# `Money` is a value object and should be treated as immutable.
struct Money
  extend Money::Constructors
  extend Money::Parse

  include Money::Casting
  include Money::Arithmetic
  include Money::Allocate
  include Money::Formatting
  include Money::Exchange

  include Comparable(Money)

  # Use this to enable infinite precision cents
  class_property? infinite_precision : Bool = false

  # Sets the default currency for creating new `Money` object.
  class_property default_currency : Currency { Currency.find("USD") }

  # ditto
  def self.default_currency=(currency_code : String | Symbol)
    self.default_currency = Currency.find(currency_code)
  end

  # Each `Money` object is associated to a bank object, which is responsible
  # for currency exchange. This property allows you to specify the default
  # bank object. The default value for this property is an instance of
  # `Bank::VariableExchange`. It allows one to specify custom exchange rates.
  class_property default_bank : Bank { Bank::VariableExchange.new }

  # Sets the default bank to be a `Bank::SingleCurrency` bank that raises on
  # currency exchange. Useful when apps operate in a single currency at a time.
  def self.disallow_currency_conversion!
    self.default_bank = Bank::SingleCurrency.new
  end

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
    initialize(amount.to_big_d, currency)
  end

  # :nodoc:
  def initialize(fractional : Int, currency, bank)
    @currency = Currency.wrap(currency)
    @amount = fractional.to_big_d / @currency.subunit_to_unit
    @bank = bank
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
  # See `#to_big_d` and `#fractional`.
  def amount : BigDecimal
    return @amount if Money.infinite_precision?
    @amount.round(currency.exponent)
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
  # FIXME: Doesn't work with `Money.infinite_precision?` yet
  def fractional : BigInt
    (amount * currency.subunit_to_unit).to_big_i
  end

  # Alias of `#amount`.
  def dollars : BigDecimal
    amount
  end

  # Alias of `#fractional`.
  def cents : BigInt
    fractional
  end

  # Returns the nearest possible amount in cash value (cents).
  #
  # For example, in Swiss franc (CHF), the smallest possible amount of
  # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
  # and for CHF 0.08, CHF 0.10.
  def nearest_cash_value : BigInt
    unless smallest_denomination = currency.smallest_denomination
      raise UndefinedSmallestDenominationError.new
    end
    rounded_value = (fractional.to_big_d / smallest_denomination).round
    rounded_value *= smallest_denomination
    rounded_value.to_big_i
  end

  # See `#nearest_cash_value`.
  def rounded_to_nearest_cash_value : Money
    copy_with(fractional: nearest_cash_value)
  end
end
