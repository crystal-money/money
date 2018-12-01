require "./currency/*"

struct Money
  # Represents a specific currency unit.
  #
  # See [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217).
  class Currency
    include Comparable(Currency)
    include Comparable(String | Symbol)

    extend Currency::Loader
    extend Currency::Enumeration

    # List of known currencies.
    class_getter table : Hash(String, Currency) { load_currencies }

    def self.register(currency : Currency)
      table[currency.id] = currency
    end

    def self.unregister(currency : Currency)
      table.delete(currency.id)
    end

    def self.unregister(currency_code : String | Symbol)
      find?(currency_code).try do |currency|
        table.delete(currency.id)
      end
    end

    # Wraps the *value* in a `Currency` object.
    #
    # ```
    # c1 = Money::Currency.find(:usd)
    # Money::Currency.wrap?(c1)    # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?("usd") # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?(:usd)  # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?(nil)   # => nil
    # ```
    def self.wrap?(value : String | Symbol | Currency | Nil) : Currency?
      case value
      when String, Symbol then find(value)
      when Currency       then value
      when Nil            then nil
      end
    end

    # ditto
    def self.wrap(value : String | Symbol | Currency | Nil) : Currency
      wrap?(value) || raise UnknownCurrencyError.new("Can't find currency: #{value}")
    end

    getter priority : Int32?
    getter iso_numeric : UInt32?
    getter code : String
    getter name : String?
    getter symbol : String?
    getter alternate_symbols : Array(String)?
    getter subunit : String?
    getter subunit_to_unit : UInt64
    getter? symbol_first : Bool?
    getter html_entity : String?
    getter decimal_mark : String?
    getter thousands_separator : String?
    getter smallest_denomination : UInt32?

    # Currency ID, for time being lower-cased `#code`.
    getter id : String { code.downcase }

    def_equals_and_hash id

    # Returns the relation between subunit and unit as a base 10 exponent.
    #
    # NOTE: MGA and MRO are exceptions and are rounded to 1.
    #
    # See [Active_codes](https://en.wikipedia.org/wiki/ISO_4217#Active_codes).
    def exponent : Int32
      Math.log10(subunit_to_unit).round.to_i
    end

    # Alias of `#exponent`.
    def decimal_places : Int32
      exponent
    end

    # Returns `true` if iso currency.
    #
    # See `#iso_numeric`.
    def iso?
      !!iso_numeric
    end

    # Compares `self` with *other* currency against the value of
    # `priority` and `id` attributes.
    def <=>(other : Currency) : Int32
      # ameba:disable Lint/LiteralInCondition
      case {(priority = self.priority), (other_priority = other.priority)}
      when {Int32, Int32}
        comparison = priority <=> other_priority
        return id <=> other.id if comparison == 0
        comparison
      when {nil, Int32}
        1
      when {Int32, nil}
        -1
      else
        id <=> other.id
      end
    end

    # Compares `self` with *other* currency against the value of id` attribute.
    def <=>(other : String | Symbol) : Int32
      id <=> other.to_s.downcase
    end

    # Appends a string representation corresponding to the `#code` property
    # to the given *io*.
    #
    # ```
    # Money::Currency.find(:usd).to_s # => "USD"
    # Money::Currency.find(:eur).to_s # => "EUR"
    # ```
    def to_s(io)
      io << code
    end
  end
end
