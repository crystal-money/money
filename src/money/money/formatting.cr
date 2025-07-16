struct Money
  module Formatting
    # Creates a formatted price string according to several rules.
    #
    # **display_free**
    #
    # Whether a zero amount of money should be formatted as the supplied string.
    #
    # ```
    # Money.us_dollar(0).format(display_free: "gratis") # => "gratis"
    # Money.us_dollar(0).format                         # => "$0.00"
    # ```
    #
    # **sign_positive**
    #
    # Whether positive numbers should be signed, too.
    #
    # ```
    # # You can specify to display the sign with positive numbers
    # Money.new(1_00, "GBP").format(sign_positive: true) # => "+£1.00"
    # Money.new(1_00, "GBP").format                      # => "£1.00"
    # ```
    #
    # **with_currency**
    #
    # Whether the currency name should be appended to the result string.
    #
    # ```
    # Money.us_dollar(100).format                      # => "$1.00"
    # Money.us_dollar(100).format(with_currency: true) # => "$1.00 USD"
    # Money.us_dollar(85).format(with_currency: true)  # => "$0.85 USD"
    # ```
    #
    # **no_cents**
    #
    # Whether cents should be omitted.
    #
    # ```
    # Money.us_dollar(1_00).format(no_cents: true) # => "$1"
    # Money.us_dollar(5_99).format(no_cents: true) # => "$5"
    # ```
    #
    # **no_cents_if_whole**
    #
    # Whether cents should be omitted if the cent value is zero.
    #
    # ```
    # Money.us_dollar(100_00).format(no_cents_if_whole: true) # => "$100"
    # Money.us_dollar(100_34).format(no_cents_if_whole: true) # => "$100.34"
    # ```
    #
    # **drop_trailing_zeros**
    #
    # ```
    # Money.new(89000, :btc).format(drop_trailing_zeros: true) # => ฿0.00089
    # Money.new(110, :usd).format(drop_trailing_zeros: true)   # => $1.1
    # ```
    #
    # **symbol_first**
    #
    # Whether a money symbol should go before the amount.
    #
    # ```
    # Money.new(100_00, "USD").format(symbol_first: true)  # => "$100.00"
    # Money.new(100_00, "USD").format(symbol_first: false) # => "100.00 $"
    # ```
    #
    # **symbol**
    #
    # Whether a money symbol should be prepended to the result string.
    # This method attempts to pick a symbol that's suitable for the given currency.
    #
    # ```
    # Money.new(1_00, "USD") # => "$1.00"
    # Money.new(1_00, "GBP") # => "£1.00"
    # Money.new(1_00, "EUR") # => "€1.00"
    #
    # # Same thing.
    # Money.new(1_00, "USD").format(symbol: true) # => "$1.00"
    # Money.new(1_00, "GBP").format(symbol: true) # => "£1.00"
    # Money.new(1_00, "EUR").format(symbol: true) # => "€1.00"
    #
    # # You can pass `false` or an empty string to disable
    # # prepending a money symbol.
    # Money.new(1_00, "USD").format(symbol: false) # => "1.00"
    # Money.new(1_00, "EUR").format(symbol: "")    # => "1.00"
    #
    # # If the symbol for the given currency isn't known, then it will default
    # # to "¤" as symbol.
    # Money.new(1_00, "XBC").format(symbol: true) # => "1.00 ¤"
    #
    # # You can specify a string as value to enforce using a particular symbol.
    # Money.new(1_00, "XBC").format(symbol: "ƒ") # => "1.00 ƒ"
    # ```
    #
    # **disambiguate**
    #
    # Prevents the result from being ambiguous due to equal symbols for different currencies.
    # Uses the `disambiguate_symbol`.
    #
    # ```
    # Money.new(100_00, "USD").format(disambiguate: false) # => "$100.00"
    # Money.new(100_00, "CAD").format(disambiguate: false) # => "$100.00"
    # Money.new(100_00, "USD").format(disambiguate: true)  # => "US$100.00"
    # Money.new(100_00, "CAD").format(disambiguate: true)  # => "C$100.00"
    # ```
    #
    # **symbol_before_without_space**
    #
    # Whether a space between the money symbol and the amount should be inserted
    # when `:symbol_first` is `true`. The default is `true` (meaning no space).
    # Ignored if `:symbol` is `false` or `:symbol_first` is `false`.
    #
    # ```
    # # Default is to not insert a space.
    # Money.new(1_00, "USD").format # => "$1.00"
    #
    # # Same thing.
    # Money.new(1_00, "USD").format(symbol_before_without_space: true) # => "$1.00"
    #
    # # If set to false, will insert a space.
    # Money.new(1_00, "USD").format(symbol_before_without_space: false) # => "$ 1.00"
    # ```
    #
    # **symbol_after_without_space**
    #
    # Whether a space between the amount and the money symbol should be inserted
    # when `:symbol_first` is `false`. The default is `false` (meaning space).
    # Ignored if `:symbol` is `false` or `:symbol_first` is `true`.
    #
    # ```
    # # Default is to insert a space.
    # Money.new(1_00, "USD").format(symbol_first: false) # => "1.00 $"
    #
    # # If set to true, will not insert a space.
    # Money.new(1_00, "USD").format(symbol_first: false, symbol_after_without_space: true) # => "1.00$"
    # ```
    #
    # **separator**
    #
    # Whether the currency should be separated by the specified character or ".".
    #
    # ```
    # # If a string is specified, it's value is used.
    # Money.new(1_00, "USD").format(separator: ",") # => "$1,00"
    #
    # # If the separator for a given currency isn't known, then it will default
    # # to "." as separator.
    # Money.new(1_00, "FOO").format # => "$1.00"
    # ```
    #
    # **delimiter**
    #
    # Whether the currency should be delimited by the specified character or ",".
    #
    # ```
    # # If falsy value is specified, no delimiter is used.
    # Money.new(1_000_00, "USD").format(delimiter: false) # => "1000.00"
    # Money.new(1_000_00, "USD").format(delimiter: "")    # => "1000.00"
    #
    # # If a string is specified, it's value is used.
    # Money.new(1_000_00, "USD").format(delimiter: ".") # => "$1.000.00"
    #
    # # If the delimiter for a given currency isn't known, then it will
    # # default to "," as delimiter.
    # Money.new(1_000_00, "FOO").format # => "$1,000.00"
    # ```
    #
    # **html**
    #
    # Whether the currency should be HTML-formatted.
    #
    # ```
    # Money.new(19_99, "RUB").format(html: true, no_cents: true) # => "19 &#x20BD;"
    # ```
    def format(
      *,
      display_free : String? = nil,
      sign_positive : Bool = false,
      with_currency : Bool = false,
      html : Bool = false,
      no_cents : Bool = false,
      no_cents_if_whole : Bool = false,
      drop_trailing_zeros : Bool = false,
      disambiguate : Bool = false,
      symbol_before_without_space : Bool = true,
      symbol_after_without_space : Bool = false,
      symbol_first : Bool = !!currency.symbol_first?,
      symbol : String | Char | Bool? = nil,
      separator : String | Char | Bool? = nil,
      delimiter : String | Char | Bool? = nil,
    ) : String
      if zero? && display_free
        return display_free
      end

      separator = currency.decimal_mark || "." if separator.in?(true, nil)
      delimiter = currency.thousands_separator || "," if delimiter.in?(true, nil)

      unit, _, subunit =
        amount.abs
          .format(separator: '.', delimiter: ',', group: 3)
          .rpartition('.')

      formatted =
        unit.gsub(',', delimiter || "")

      display_cents = true
      display_cents = false if no_cents || (no_cents_if_whole && subunit == "0")

      if display_cents && currency.decimal_places.positive?
        subunit = subunit.ljust(currency.decimal_places, '0')
        subunit = subunit.rstrip('0') if drop_trailing_zeros

        if subunit = subunit.presence
          formatted += separator if separator
          formatted += subunit
        end
      end

      default_symbol =
        if disambiguate && currency.disambiguate_symbol
          currency.disambiguate_symbol
        else
          currency.symbol || "¤"
        end

      symbol =
        if html && currency.html_entity
          currency.html_entity
        else
          case symbol
          in Nil
            default_symbol
          in Bool
            default_symbol if symbol
          in String, Char
            symbol.to_s
          end
        end

      if symbol = symbol.presence
        if symbol_first
          symbol_space = symbol_before_without_space ? nil : ' '
          formatted = "#{symbol}#{symbol_space}#{formatted}"
        else
          symbol_space = symbol_after_without_space ? nil : ' '
          formatted = "#{formatted}#{symbol_space}#{symbol}"
        end
      end

      sign = '-' if negative?
      sign = '+' if positive? && sign_positive

      formatted = "#{sign}#{formatted}" if sign
      formatted = "#{formatted} #{currency}" if with_currency
      formatted
    end

    # See also `#format`.
    def to_s(io : IO) : Nil
      io << format
    end
  end
end
