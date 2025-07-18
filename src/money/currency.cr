require "./currency/type"
require "./currency/enumeration"
require "./currency/loader"
require "./currency/exchange"
require "./currency/rate"
require "./currency/rate_store"
require "./currency/rate_provider"

struct Money
  # Represents a specific currency unit.
  #
  # See [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217).
  class Currency
    include Comparable(Currency)

    extend Currency::Loader
    extend Currency::Enumeration

    @@registry_mutex = Mutex.new(:reentrant)
    @@registry : Hash(String, Currency)?

    # List of known currencies.
    def self.registry : Hash(String, Currency)
      @@registry_mutex.synchronize do
        @@registry ||= load_currencies
      end
    end

    # Registers a new currency.
    def self.register(currency : Currency) : Currency
      @@registry_mutex.synchronize do
        registry[currency.id] = currency
      end
    end

    # Unregisters a currency.
    def self.unregister(currency : String | Symbol | Currency) : Currency?
      if currency = wrap?(currency)
        @@registry_mutex.synchronize do
          registry.delete(currency.id)
        end
      end
    end

    # Resets all registered currencies to their defaults.
    def self.reset! : Nil
      @@registry_mutex.synchronize do
        @@registry = load_currencies
      end
    end

    # Wraps the *value* in a `Currency` object.
    #
    # ```
    # c1 = Money::Currency.find(:usd)
    # Money::Currency.wrap?(c1)    # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?("usd") # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?(:usd)  # => #<Money::Currency @id="usd">
    # Money::Currency.wrap?(:foo)  # => nil
    # ```
    def self.wrap?(value : String | Symbol | Currency) : Currency?
      case value
      when String, Symbol then find?(value)
      when Currency       then value
      end
    end

    # :ditto:
    def self.wrap(value : String | Symbol | Currency) : Currency
      wrap?(value) ||
        raise UnknownCurrencyError.new(value)
    end

    # Currency ID (lower-cased `#code`).
    getter id : String { code.downcase }

    # Currency type.
    getter type : Type?

    # Currency priority (used for sorting).
    getter priority : Int32?

    # ISO 4217 numeric code.
    getter iso_numeric : Int32?

    # Currency code.
    getter code : String

    # Currency name.
    getter name : String?

    # Currency symbol.
    getter symbol : String?

    # Disambiguation symbol.
    getter disambiguate_symbol : String?

    # Alternate symbols.
    getter alternate_symbols : Array(String)?

    # Currency subunit.
    getter subunit : String?

    # Subunit to unit value.
    getter subunit_to_unit : UInt64

    # Should the symbol be placed before the amount?
    getter? symbol_first : Bool?

    # HTML entity.
    getter html_entity : String?

    # Decimal mark.
    getter decimal_mark : String?

    # Thousands separator.
    getter thousands_separator : String?

    # Smallest denomination.
    getter smallest_denomination : Int32?

    def initialize(
      *,
      @type = nil,
      @priority = nil,
      @iso_numeric = nil,
      @code,
      @name = nil,
      @symbol = nil,
      @disambiguate_symbol = nil,
      @alternate_symbols = nil,
      @subunit = nil,
      @subunit_to_unit,
      @symbol_first = nil,
      @html_entity = nil,
      @decimal_mark = nil,
      @thousands_separator = nil,
      @smallest_denomination = nil,
    )
      unless code.presence &&
             code.chars.all? { |char| char.ascii_uppercase? || char.ascii_number? }
        raise ArgumentError.new \
          "Code must be all uppercase letters and/or digits: #{code.inspect}"
      end
      unless subunit_to_unit.positive?
        raise ArgumentError.new \
          "Subunit to unit value must be positive: #{subunit_to_unit}"
      end
      if iso_numeric && !iso_numeric.positive?
        raise ArgumentError.new \
          "ISO numeric value must be positive: #{iso_numeric}"
      end
      if smallest_denomination && !smallest_denomination.positive?
        raise ArgumentError.new \
          "Smallest denomination value must be positive: #{smallest_denomination}"
      end
    end

    def_equals_and_hash id

    {% for type in Type.constants.map(&.underscore.id) %}
      # Returns `true` if the currency `#type` is `{{ type }}`, otherwise `false`.
      def {{ type }}? : Bool
        !!type.try(&.{{ type }}?)
      end
    {% end %}

    # Returns the relation between subunit and unit as a base 10 exponent.
    #
    # NOTE: MGA and MRU are exceptions and are rounded to 1.
    #
    # See [Active_codes](https://en.wikipedia.org/wiki/ISO_4217#Active_codes).
    def exponent : Int32
      Math.log10(subunit_to_unit).round.to_i
    end

    # Alias of `#exponent`.
    @[AlwaysInline]
    def decimal_places : Int32
      exponent
    end

    # Returns `true` if iso currency.
    #
    # See also `#iso_numeric`.
    def iso? : Bool
      !!iso_numeric
    end

    # Returns `true` if a subunit is cents-based.
    #
    # ````
    # Money::Currency.find(:usd).cents_based? # => true
    # ````
    def cents_based? : Bool
      subunit_to_unit == 100
    end

    # Compares `self` with *other* currency against the value of
    # `priority` and `id` attributes.
    def <=>(other : Currency) : Int32
      case {(priority = self.priority), (other_priority = other.priority)}
      in {Int32, Int32}
        comparison = priority <=> other_priority
        comparison = id <=> other.id if comparison.zero?
        comparison
      in {Int32, nil} then -1
      in {nil, Int32} then 1
      in {nil, nil}
        id <=> other.id
      end
    end

    # Appends a string representation corresponding to the `#code` property
    # to the given *io*.
    #
    # ```
    # Money::Currency.find(:usd).to_s # => "USD"
    # Money::Currency.find(:eur).to_s # => "EUR"
    # ```
    def to_s(io : IO) : Nil
      io << code
    end
  end
end

require "./currency/json"
require "./currency/yaml"
