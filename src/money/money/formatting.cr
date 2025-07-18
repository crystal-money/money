struct Money
  module Formatting
    # Creates a formatted price string according to several rules.
    #
    # ### `:format`
    #
    # The format string to use for the resulting string.
    #
    # ```
    # Money.us_dollar(-1_23).format(format: "%{sign}%{symbol}%{amount}")    # => "-$1.23"
    # Money.us_dollar(-1_23).format(format: "%{sign}%{amount} %{currency}") # => "-1.23 USD"
    # ```
    #
    # ### `:display_free`
    #
    # Whether a zero amount of money should be formatted as the supplied string.
    #
    # ```
    # Money.us_dollar(0).format(display_free: "gratis") # => "gratis"
    # Money.us_dollar(0).format                         # => "$0.00"
    # ```
    #
    # ### `:sign_positive`
    #
    # Whether positive numbers should be signed, too.
    #
    # ```
    # Money.new(1_00, "GBP").format(sign_positive: true) # => "+£1.00"
    # Money.new(1_00, "GBP").format                      # => "£1.00"
    # ```
    #
    # ### `:no_cents`
    #
    # Whether cents should be omitted.
    #
    # ```
    # Money.us_dollar(1_00).format(no_cents: true) # => "$1"
    # Money.us_dollar(5_99).format(no_cents: true) # => "$5"
    # ```
    #
    # ### `:no_cents_if_whole`
    #
    # Whether cents should be omitted if the cent value is zero.
    #
    # ```
    # Money.us_dollar(100_00).format(no_cents_if_whole: true) # => "$100"
    # Money.us_dollar(100_34).format(no_cents_if_whole: true) # => "$100.34"
    # ```
    #
    # ### `:drop_trailing_zeros`
    #
    # Whether trailing zeros should be omitted.
    #
    # ```
    # Money.new(89000, :btc).format(drop_trailing_zeros: true) # => ฿0.00089
    # Money.new(1_10, :usd).format(drop_trailing_zeros: true)  # => $1.1
    # ```
    #
    # ### `:symbol`
    #
    # Specifies the currency symbol to be used.
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
    # # You can pass `false` or an empty string to disable prepending a money symbol.
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
    # ### `:disambiguate`
    #
    # Prevents the result from being ambiguous due to equal symbols for different currencies.
    # Uses the `Currency#disambiguate_symbol`.
    #
    # ```
    # Money.new(100_00, "USD").format(disambiguate: false) # => "$100.00"
    # Money.new(100_00, "CAD").format(disambiguate: false) # => "$100.00"
    # Money.new(100_00, "USD").format(disambiguate: true)  # => "US$100.00"
    # Money.new(100_00, "CAD").format(disambiguate: true)  # => "C$100.00"
    # ```
    #
    # ### `:decimal_mark`
    #
    # Decimal mark to use between the whole and fractional parts of the number.
    #
    # ```
    # # If a string is specified, it's value is used.
    # Money.new(1_00, "USD").format(decimal_mark: ",") # => "$1,00"
    #
    # # If the separator for a given currency isn't known, then it will default to ".".
    # Money.new(1_00, "FOO").format # => "$1.00"
    # ```
    #
    # ### `:thousands_separator`
    #
    # Thousands separator to use between groups of three digits.
    #
    # ```
    # # If false or empty value is specified, no delimiter is used.
    # Money.new(1_000_00, "USD").format(thousands_separator: false) # => "1000.00"
    # Money.new(1_000_00, "USD").format(thousands_separator: "")    # => "1000.00"
    #
    # # If a string is specified, it's value is used.
    # Money.new(1_000_00, "USD").format(thousands_separator: ".") # => "$1.000.00"
    #
    # # If the delimiter for a given currency isn't known, then it will default to ",".
    # Money.new(1_000_00, "FOO").format # => "$1,000.00"
    # ```
    #
    # ### `:html`
    #
    # Whether the currency symbol should be HTML-formatted.
    #
    # ```
    # Money.new(19_99, "RUB").format(html: true, no_cents: true) # => "19 &#x20BD;"
    # ```
    def format(
      *,
      format : String? = nil,
      display_free : String? = nil,
      sign_positive : Bool = false,
      html : Bool = false,
      no_cents : Bool = false,
      no_cents_if_whole : Bool = false,
      drop_trailing_zeros : Bool = false,
      disambiguate : Bool = false,
      symbol : String | Char | Bool? = nil,
      decimal_mark : String | Char | Bool? = nil,
      thousands_separator : String | Char | Bool? = nil,
    ) : String
      if zero? && display_free
        return display_free
      end

      formatted_amount = format_amount(
        no_cents: no_cents,
        no_cents_if_whole: no_cents_if_whole,
        drop_trailing_zeros: drop_trailing_zeros,
        decimal_mark: decimal_mark,
        thousands_separator: thousands_separator,
      )

      symbol = format_symbol(
        disambiguate: disambiguate,
        symbol: symbol,
        html: html,
      )

      sign = '-' if negative?
      sign = '+' if positive? && sign_positive

      format ||=
        if currency.symbol_first?
          "%{sign}%{symbol}%{amount}"
        else
          "%{sign}%{amount} %{symbol}"
        end

      formatted = format % {
        sign:     sign,
        amount:   formatted_amount,
        symbol:   symbol.presence,
        currency: currency.code,
      }
      formatted.strip
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def format_amount(*, no_cents, no_cents_if_whole, drop_trailing_zeros, decimal_mark, thousands_separator) : String
      decimal_mark =
        currency.decimal_mark || "." if decimal_mark.in?(true, nil)

      thousands_separator =
        currency.thousands_separator || "," if thousands_separator.in?(true, nil)

      unit, _, subunit =
        amount.abs
          .format(separator: '.', delimiter: ',', group: 3)
          .rpartition('.')

      formatted =
        unit.gsub(',', thousands_separator || "")

      hide_cents =
        no_cents || (no_cents_if_whole && subunit == "0")

      if !hide_cents && currency.decimal_places.positive?
        subunit = subunit.ljust(currency.decimal_places, '0')
        subunit = subunit.rstrip('0') if drop_trailing_zeros

        if subunit = subunit.presence
          formatted += decimal_mark if decimal_mark
          formatted += subunit
        end
      end

      formatted
    end

    private def format_symbol(*, disambiguate, symbol, html) : String?
      default_symbol =
        if disambiguate && currency.disambiguate_symbol
          currency.disambiguate_symbol
        else
          currency.symbol || "¤"
        end

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
    end

    # See also `#format`.
    def to_s(io : IO) : Nil
      io << format
    end
  end
end
