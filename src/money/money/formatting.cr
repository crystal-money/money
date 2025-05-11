struct Money
  module Formatting
    private DELIMITER_REGEX = /(\d)(?=(\d\d\d)+(?!\d))/

    # Creates a formatted price string according to several rules.
    #
    # **display_free** (`Bool | String`) — default: `false`
    #
    # Whether a zero amount of money should be formatted as the supplied string.
    #
    # ```
    # Money.us_dollar(0).format(display_free: "gratis") # => "gratis"
    # Money.us_dollar(0).format                         # => "$0.00"
    # ```
    #
    # **sign_positive** (`Bool`) — default: `false`
    #
    # Whether positive numbers should be signed, too.
    #
    # ```
    # # You can specify to display the sign with positive numbers
    # Money.new(100, "GBP").format(sign_positive: true) # => "+£1.00"
    # Money.new(100, "GBP").format                      # => "£1.00"
    # ```
    #
    # **with_currency** (`Bool`) — default: `false`
    #
    # Whether the currency name should be appended to the result string.
    #
    # ```
    # Money.us_dollar(100).format                      # => "$1.00"
    # Money.us_dollar(100).format(with_currency: true) # => "$1.00 USD"
    # Money.us_dollar(85).format(with_currency: true)  # => "$0.85 USD"
    # ```
    #
    # **no_cents** (`Bool`) — default: `false`
    #
    # Whether cents should be omitted.
    #
    # ```
    # Money.us_dollar(100).format(no_cents: true) # => "$1"
    # Money.us_dollar(599).format(no_cents: true) # => "$5"
    # ```
    #
    # **no_cents_if_whole** (`Bool`) — default: `false`
    #
    # Whether cents should be omitted if the cent value is zero.
    #
    # ```
    # Money.us_dollar(10000).format(no_cents_if_whole: true) # => "$100"
    # Money.us_dollar(10034).format(no_cents_if_whole: true) # => "$100.34"
    # ```
    #
    # **drop_trailing_zeros** (`Bool`) — default: `false`
    #
    # ```
    # Money.new(89000, :btc).format(drop_trailing_zeros: true) # => ฿0.00089
    # Money.new(110, :usd).format(drop_trailing_zeros: true)   # => $1.1
    # ```
    #
    # **symbol_first** (`Bool`) — default: `false`
    #
    # Whether a money symbol should go before the amount.
    #
    # ```
    # Money.new(10000, "USD").format(symbol_first: true)  # => "$100.00"
    # Money.new(10000, "USD").format(symbol_first: false) # => "100.00 $"
    # ```
    #
    # **symbol** (`Bool | String`) — default: `true`
    #
    # Whether a money symbol should be prepended to the result string.
    # This method attempts to pick a symbol that's suitable for the given currency.
    #
    # ```
    # Money.new(100, "USD") # => "$1.00"
    # Money.new(100, "GBP") # => "£1.00"
    # Money.new(100, "EUR") # => "€1.00"
    #
    # # Same thing.
    # Money.new(100, "USD").format(symbol: true) # => "$1.00"
    # Money.new(100, "GBP").format(symbol: true) # => "£1.00"
    # Money.new(100, "EUR").format(symbol: true) # => "€1.00"
    #
    # # You can pass `false` or an empty string to disable
    # # prepending a money symbol.
    # Money.new(100, "USD").format(symbol: false) # => "1.00"
    # Money.new(100, "GBP").format(symbol: nil)   # => "1.00"
    # Money.new(100, "EUR").format(symbol: "")    # => "1.00"
    #
    # # If the symbol for the given currency isn't known, then it will default
    # # to "¤" as symbol.
    # Money.new(100, "XBC").format(symbol: true) # => "1.00 ¤"
    #
    # # You can specify a string as value to enforce using a particular symbol.
    # Money.new(100, "XBC").format(symbol: "ƒ") # => "1.00 ƒ"
    # ```
    #
    # **disambiguate** (`Bool`) — default: `false`
    #
    # Prevents the result from being ambiguous due to equal symbols for different currencies.
    # Uses the `disambiguate_symbol`.
    #
    # ```
    # Money.new(100, "USD").format(disambiguate: false) # => "$100.00"
    # Money.new(100, "CAD").format(disambiguate: false) # => "$100.00"
    # Money.new(100, "USD").format(disambiguate: true)  # => "US$100.00"
    # Money.new(100, "CAD").format(disambiguate: true)  # => "C$100.00"
    # ```
    #
    # **symbol_before_without_space** (`Bool`) — default: `true`
    #
    # Whether a space between the money symbol and the amount should be inserted
    # when `:symbol_first` is `true`. The default is `true` (meaning no space).
    # Ignored if `:symbol` is `false` or `:symbol_first` is `false`.
    #
    # ```
    # # Default is to not insert a space.
    # Money.new(100, "USD").format # => "$1.00"
    #
    # # Same thing.
    # Money.new(100, "USD").format(symbol_before_without_space: true) # => "$1.00"
    #
    # # If set to false, will insert a space.
    # Money.new(100, "USD").format(symbol_before_without_space: false) # => "$ 1.00"
    # ```
    #
    # **symbol_after_without_space** (`Bool`) — default: `false`
    #
    # Whether a space between the amount and the money symbol should be inserted
    # when `:symbol_first` is `false`. The default is `false` (meaning space).
    # Ignored if `:symbol` is `false` or `:symbol_first` is `true`.
    #
    # ```
    # # Default is to insert a space.
    # Money.new(100, "USD").format(symbol_first: false) # => "1.00 $"
    #
    # # If set to true, will not insert a space.
    # Money.new(100, "USD").format(symbol_first: false, symbol_after_without_space: true) # => "1.00$"
    # ```
    #
    # **separator** (`Bool | String`) — default: `true`
    #
    # Whether the currency should be separated by the specified character or ".".
    #
    # ```
    # # If a string is specified, it's value is used.
    # Money.new(100, "USD").format(separator: ",") # => "$1,00"
    #
    # # If the separator for a given currency isn't known, then it will default
    # # to "." as separator.
    # Money.new(100, "FOO").format # => "$1.00"
    # ```
    #
    # **delimiter** (`Bool | String`) — default: `true`
    #
    # Whether the currency should be delimited by the specified character or ",".
    #
    # ```
    # # If falsy value is specified, no delimiter is used.
    # Money.new(100000, "USD").format(delimiter: false) # => "1000.00"
    # Money.new(100000, "USD").format(delimiter: nil)   # => "1000.00"
    # Money.new(100000, "USD").format(delimiter: "")    # => "1000.00"
    #
    # # If a string is specified, it's value is used.
    # Money.new(100000, "USD").format(delimiter: ".") # => "$1.000.00"
    #
    # # If the delimiter for a given currency isn't known, then it will
    # # default to "," as delimiter.
    # Money.new(100000, "FOO").format # => "$1,000.00"
    # ```
    #
    # **html** (`Bool`) — default: `false`
    #
    # Whether the currency should be HTML-formatted.
    #
    # ```
    # Money.new(1999, "RUB").format(html: true, no_cents: true) # => "19 &#x20BD;"
    # ```
    def format(options : NamedTuple) : String
      default_options = {
        display_free:                false,
        sign_positive:               false,
        with_currency:               false,
        html:                        false,
        no_cents:                    false,
        no_cents_if_whole:           false,
        drop_trailing_zeros:         false,
        disambiguate:                false,
        symbol_before_without_space: true,
        symbol_after_without_space:  false,
        symbol_first:                currency.symbol_first? || false,
        separator:                   currency.decimal_mark || ".",
        delimiter:                   currency.thousands_separator || ",",
      }
      options = default_options.merge(options)

      {% for key in %i[separator delimiter] %}
        if options[{{ key }}] === true
          options = options.merge {{ key.id }}: default_options[{{ key }}]
        end
      {% end %}

      if zero?
        display_free = options[:display_free]
        if display_free.is_a?(String)
          return display_free
        end
      end

      parts = amount.abs.to_s.split('.')
      unit, subunit = parts[0], parts[1]?
      subunit = nil if subunit == "0"

      formatted = unit

      delimiter = options[:delimiter]
      if delimiter
        formatted = formatted.gsub(DELIMITER_REGEX) do |digit_to_delimit|
          "#{digit_to_delimit}#{delimiter}"
        end
      end

      display_cents = true
      if options[:no_cents] || (options[:no_cents_if_whole] && !subunit)
        display_cents = false
      end

      decimal_places = currency.decimal_places
      if display_cents && decimal_places > 0
        subunit = subunit.to_s.ljust(decimal_places, '0')
        subunit = subunit.rstrip('0') if options[:drop_trailing_zeros]
        unless subunit.empty?
          formatted += "#{options[:separator]}#{subunit}"
        end
      end

      sign = negative? ? '-' : (options[:sign_positive] && positive?) ? '+' : nil

      default_symbol =
        if options[:disambiguate] && currency.disambiguate_symbol
          currency.disambiguate_symbol
        else
          currency.symbol || "¤"
        end

      symbol =
        case
        when options[:html] && currency.html_entity
          currency.html_entity
        when options.has_key?(:symbol)
          case options[:symbol]?
          when true
            default_symbol
          when String
            options[:symbol]?
          end
        else
          default_symbol
        end

      if symbol.is_a?(String) && !symbol.empty?
        if options[:symbol_first]
          symbol_space = options[:symbol_before_without_space] ? nil : ' '
          formatted = "#{sign}#{symbol}#{symbol_space}#{formatted}"
        else
          symbol_space = options[:symbol_after_without_space] ? nil : ' '
          formatted = "#{sign}#{formatted}#{symbol_space}#{symbol}"
        end
      else
        formatted = "#{sign}#{formatted}"
      end

      formatted += " #{currency}" if options[:with_currency]
      formatted
    end

    # :nodoc:
    def format(**options) : String
      format(options)
    end

    # See `#format`.
    def to_s(io : IO) : Nil
      io << format
    end
  end
end
