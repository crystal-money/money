require "./money/*"

# "Money is any object or record that is generally accepted as payment for
# goods and services and repayment of debts in a given socio-economic context
# or country." - [Wikipedia](http://en.wikipedia.org/wiki/Money)
#
# An instance of `Money` represents an amount of a specific currency.
#
# `Money` is a value object and should be treated as immutable.
class Money
  extend Money::Constructors
  extend Money::Parse

  include Money::Casting
  include Money::Arithmetic
  include Money::Allocate
  include Money::Formatting
  include Money::Exchange

  include Comparable(Money)

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
  getter fractional : Int64

  # The money's currency.
  getter currency : Currency

  # Creates a new `Money` object of value given in the
  # *fractional* unit of the given *currency*.
  #
  # ```
  # Money.new(100)        # => #<Money @fractional=100 @currency="USD">
  # Money.new(100, "USD") # => #<Money @fractional=100 @currency="USD">
  # Money.new(100, "EUR") # => #<Money @fractional=100 @currency="EUR">
  # ```
  def initialize(fractional, currency = Money.default_currency)
    @fractional = fractional.to_i64
    @currency = Currency.wrap(currency)
  end

  # Creates a new `Money` object of value given in the
  # *fractional* unit of the given *currency*.
  #
  # ```
  # Money.new(1.0)               # => #<Money @fractional=100 @currency="USD">
  # Money.new(1.to_big_d, "USD") # => #<Money @fractional=100 @currency="USD">
  # Money.new(1.to_big_r, "EUR") # => #<Money @fractional=100 @currency="EUR">
  # ```
  def initialize(fractional : Float | BigDecimal | BigRational, currency = Money.default_currency)
    if fractional.responds_to?(:finite?) && !fractional.finite?
      raise ArgumentError.new "Must be initialized with a finite value"
    end
    @fractional = fractional.round.to_f64.to_i64
    @currency = Currency.wrap(currency)
  end

  # Returns hash value based on the `fractional` and `currency` attributes.
  def_hash @fractional, @currency

  # Compares two `Money` objects.
  def <=>(other : Money) : Int32
    return 0 if zero? && other.zero?
    with_same_currency(other) do |converted_other|
      fractional <=> converted_other.fractional
    end
  end

  # The `Bank` object which currency exchanges are performed with.
  def bank : Bank
    Money.default_bank
  end

  # Returns the numerical value of the money.
  #
  # ```
  # Money.new(1_00, "USD").amount # => BigDecimal.new("1.00")
  # ```
  #
  # See `#to_big_d` and `#fractional`.
  def amount : BigDecimal
    to_big_d
  end

  # Alias of `#amount`.
  def dollars : BigDecimal
    amount
  end

  # Alias of `#fractional`.
  def cents : Int64
    fractional
  end

  # Returns the nearest possible amount in cash value.
  #
  # For example, in Swiss franc (CHF), the smallest possible amount of
  # cash value is CHF 0.05. Therefore, for CHF 0.07 this method returns CHF 0.05,
  # and for CHF 0.08, CHF 0.10.
  def nearest_cash_value : Int64
    smallest_denomination = currency.smallest_denomination
    unless smallest_denomination
      raise UndefinedSmallestDenominationError.new
    end
    rounded_value = (fractional.to_big_d / smallest_denomination).round * smallest_denomination
    rounded_value.to_i64
  end

  # See `#nearest_cash_value`.
  def rounded_to_nearest_cash_value : Money
    Money.new(nearest_cash_value, currency)
  end
end
