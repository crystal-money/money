require "../spec_helper"

describe Money::Formatting do
  bar_currency = Money::Currency.from_json(%q({
    "priority": 1,
    "code": "BAR",
    "iso_numeric": 840,
    "name": "Dollar with 4 decimal places",
    "symbol": "$",
    "subunit": "Cent",
    "subunit_to_unit": 10000,
    "symbol_first": true,
    "html_entity": "$",
    "decimal_mark": ".",
    "thousands_separator": ",",
    "smallest_denomination": 1
  }))

  eu4_currency = Money::Currency.from_json(%q({
    "priority": 1,
    "code": "EU4",
    "iso_numeric": 841,
    "name": "Euro with 4 decimal places",
    "symbol": "€",
    "subunit": "Cent",
    "subunit_to_unit": 10000,
    "symbol_first": true,
    "html_entity": "€",
    "decimal_mark": ",",
    "thousands_separator": ".",
    "smallest_denomination": 1
  }))

  describe "#format" do
    it "returns the monetary value as a string" do
      Money.new(100, "CAD").format.should eq "$1.00"
      Money.new(40008).format.should eq "$400.08"
      Money.new(1999_98, "BCH").format.should eq "0.00199998 ₿"
    end

    it "respects :subunit_to_unit currency property" do
      Money.new(10_00, "BHD").format.should eq "د.ب1.000"
    end

    it "does not display a decimal when :subunit_to_unit is 1" do
      Money.new(10_00, "VUV").format.should eq "Vt1,000"
    end

    it "respects the thousands_separator and decimal_mark defaults" do
      one_thousand = ->(currency : String) do
        Money.new(1000_00, currency).format
      end

      # Pounds
      one_thousand.call("GBP").should eq "£1,000.00"

      # Dollars
      one_thousand.call("USD").should eq "$1,000.00"
      one_thousand.call("CAD").should eq "$1,000.00"
      one_thousand.call("AUD").should eq "$1,000.00"
      one_thousand.call("NZD").should eq "$1,000.00"
      # one_thousand.call("ZWD").should eq "$1,000.00"

      # Yen
      one_thousand.call("JPY").should eq "¥100,000"
      one_thousand.call("CNY").should eq "¥1,000.00"

      # Euro
      one_thousand.call("EUR").should eq "€1.000,00"

      # Rupees
      one_thousand.call("INR").should eq "₹1,000.00"
      one_thousand.call("NPR").should eq "Rs.1,000.00"
      one_thousand.call("SCR").should eq "1,000.00 ₨"
      one_thousand.call("LKR").should eq "1,000.00 ₨"

      # Brazilian Real
      one_thousand.call("BRL").should eq "R$1.000,00"

      # Other
      one_thousand.call("SEK").should eq "1 000,00 kr"
      # one_thousand.call("GHC").should eq "₵1,000.00"
    end

    it "inserts commas into the result if the amount is sufficiently large" do
      Money.us_dollar(1_000_000_000_12).format.should eq "$1,000,000,000.12"
      Money.us_dollar(1_000_000_000_12).format(no_cents: true).should eq "$1,000,000,000"
    end

    it "inserts thousands separator into the result if the amount is sufficiently large and the currency symbol is at the end" do
      Money.euro(1_234_567_12).format.should eq "€1.234.567,12"
      Money.euro(1_234_567_12).format(no_cents: true).should eq "€1.234.567"
    end

    describe ":with_currency option" do
      it "works as documented" do
        Money.new(100, "CAD").format(with_currency: true).should eq "$1.00 CAD"
        Money.new(85, "USD").format(with_currency: true).should eq "$0.85 USD"
      end
    end

    describe ":no_cents option" do
      context "(with_currency: true)" do
        it "works as documented" do
          Money.new(100, "CAD").format(no_cents: true).should eq "$1"
          Money.new(599, "CAD").format(no_cents: true).should eq "$5"
          Money.new(570, "CAD").format(no_cents: true, with_currency: true).should eq "$5 CAD"
          Money.new(39000, "CAD").format(no_cents: true).should eq "$390"
        end
      end

      it "respects :subunit_to_unit currency property" do
        Money.new(10_00, "BHD").format(no_cents: true).should eq "د.ب1"
      end

      it "inserts thousand separators if symbol contains decimal mark and :no_cents is true" do
        Money.new(100000000, "AMD").format(no_cents: true).should eq "1,000,000 դր."
        Money.new(100000000, "USD").format(no_cents: true).should eq "$1,000,000"
        Money.new(100000000, "RUB").format(no_cents: true).should eq "1.000.000 ₽"
      end

      it "does correctly format HTML" do
        money = Money.new(1999, "RUB")
        output = money.format(html: true, no_cents: true)
        output.should eq "19 &#x20BD;"
      end
    end

    describe ":no_cents_if_whole option" do
      context "(no_cents_if_whole: true)" do
        it "works as documented" do
          Money.new(10000, "VUV").format(no_cents_if_whole: true, symbol: false).should eq "10,000"
          Money.new(10034, "VUV").format(no_cents_if_whole: true, symbol: false).should eq "10,034"
          Money.new(10000, "MGA").format(no_cents_if_whole: true, symbol: false).should eq "2,000"
          Money.new(10034, "MGA").format(no_cents_if_whole: true, symbol: false).should eq "2,006.8"
          Money.new(10000, "VND").format(no_cents_if_whole: true, symbol: false).should eq "10.000"
          Money.new(10034, "VND").format(no_cents_if_whole: true, symbol: false).should eq "10.034"
          Money.new(10000, "USD").format(no_cents_if_whole: true, symbol: false).should eq "100"
          Money.new(10034, "USD").format(no_cents_if_whole: true, symbol: false).should eq "100.34"
          Money.new(10000, "IQD").format(no_cents_if_whole: true, symbol: false).should eq "10"
          Money.new(10034, "IQD").format(no_cents_if_whole: true, symbol: false).should eq "10.034"
        end
      end

      context "(no_cents_if_whole: false)" do
        it "works as documented" do
          Money.new(10000, "VUV").format(no_cents_if_whole: false, symbol: false).should eq "10,000"
          Money.new(10034, "VUV").format(no_cents_if_whole: false, symbol: false).should eq "10,034"
          Money.new(10000, "MGA").format(no_cents_if_whole: false, symbol: false).should eq "2,000.0"
          Money.new(10034, "MGA").format(no_cents_if_whole: false, symbol: false).should eq "2,006.8"
          Money.new(10000, "VND").format(no_cents_if_whole: false, symbol: false).should eq "10.000"
          Money.new(10034, "VND").format(no_cents_if_whole: false, symbol: false).should eq "10.034"
          Money.new(10000, "USD").format(no_cents_if_whole: false, symbol: false).should eq "100.00"
          Money.new(10034, "USD").format(no_cents_if_whole: false, symbol: false).should eq "100.34"
          Money.new(10000, "IQD").format(no_cents_if_whole: false, symbol: false).should eq "10.000"
          Money.new(10034, "IQD").format(no_cents_if_whole: false, symbol: false).should eq "10.034"
        end
      end
    end

    describe ":symbol option" do
      context "(symbol: a symbol string)" do
        it "uses the given value as the money symbol" do
          Money.new(100, "GBP").format(symbol: "£").should eq "£1.00"
        end
      end

      context "(symbol: true)" do
        it "returns ¤ when currency symbol is empty" do
          Money.new(1, "XBA").format(symbol: true).should eq "1 ¤"
        end

        it "returns symbol based on the given currency code" do
          one = ->(currency : String) do
            Money.new(100, currency).format(symbol: true)
          end

          # Pounds
          one.call("GBP").should eq "£1.00"

          # Dollars
          one.call("USD").should eq "$1.00"
          one.call("CAD").should eq "$1.00"
          one.call("AUD").should eq "$1.00"
          one.call("NZD").should eq "$1.00"
          # one.call("ZWD").should eq "$1.00"

          # Yen
          one.call("JPY").should eq "¥100"
          one.call("CNY").should eq "¥1.00"

          # Euro
          one.call("EUR").should eq "€1,00"

          # Rupees
          one.call("INR").should eq "₹1.00"
          one.call("NPR").should eq "Rs.1.00"
          one.call("SCR").should eq "1.00 ₨"
          one.call("LKR").should eq "1.00 ₨"

          # Brazilian Real
          one.call("BRL").should eq "R$1,00"

          # Vietnamese Dong
          one.call("VND").should eq "100 ₫"

          # Other
          one.call("SEK").should eq "1,00 kr"
          # one.call("GHC").should eq "₵1.00"
        end
      end

      context "(symbol: \"\", nil or false)" do
        it "returns the amount without a symbol" do
          money = Money.new(100, "GBP")
          money.format(symbol: "").should eq "1.00"
          money.format(symbol: nil).should eq "1.00"
          money.format(symbol: false).should eq "1.00"

          money = Money.new(100, "JPY")
          money.format(symbol: false).should eq "100"
        end
      end

      it "defaults :symbol to true" do
        money = Money.new(100)
        money.format.should eq "$1.00"

        money = Money.new(100, "GBP")
        money.format.should eq "£1.00"

        money = Money.new(100, "EUR")
        money.format.should eq "€1,00"
      end

      context "(symbol: false)" do
        it "returns a signed amount without a symbol" do
          money = Money.new(-100, "EUR")
          money.format(symbol: false).should eq "-1,00"

          money = Money.new(100, "EUR")
          money.format(symbol: false, sign_positive: true).should eq "+1,00"
        end
      end
    end

    describe ":separator option" do
      context "(separator: a separator string)" do
        it "works as documented" do
          Money.us_dollar(100).format(separator: ",").should eq "$1,00"
        end
      end

      it "defaults to '.' if currency isn't recognized" do
        # Money.new(100, "ZWD").format.should eq "$1.00"
      end
    end

    describe ":delimiter option" do
      context "(delimiter: a delimiter string)" do
        it "works as documented" do
          Money.us_dollar(100000).format(delimiter: ".").should eq "$1.000.00"
          Money.us_dollar(200000).format(delimiter: "").should eq "$2000.00"
        end
      end

      context "(delimiter: false or nil)" do
        it "works as documented" do
          Money.us_dollar(100000).format(delimiter: false).should eq "$1000.00"
          Money.us_dollar(200000).format(delimiter: nil).should eq "$2000.00"
        end
      end

      it "defaults to ',' if currency isn't recognized" do
        # Money.new(100000, "ZWD").format.should eq "$1,000.00"
      end

      it "should respect explicit overriding of delimiter/separator when there’s no decimal component for currencies that have no subunit" do
        Money.new(300_000, "ISK").format(delimiter: ",", separator: ".").should eq "kr300,000"
      end

      it "should respect explicit overriding of delimiter/separator when there’s no decimal component for currencies with subunits that drop_trailing_zeros" do
        Money.new(300_000, "USD").format(delimiter: ".", separator: ",", drop_trailing_zeros: true).should eq "$3.000"
      end
    end

    describe ":delimiter and :separator option" do
      context "(delimiter: a delimiter string, separator: a separator string)" do
        it "works as documented" do
          Money.new(123_456_789, "USD").format(delimiter: ".", separator: ",").should eq("$1.234.567,89")
          Money.new(987_654_321, "USD").format(delimiter: " ", separator: ".").should eq("$9 876 543.21")
        end
      end
    end

    describe ":html option" do
      it "should fallback to symbol if entity is not available" do
        Money.new(570, "DKK").format(html: true).should eq "5,70 kr."
      end
    end

    describe ":symbol_first option" do
      it "inserts currency symbol before the amount when set to :before" do
        Money.euro(1_234_567_12).format(symbol_first: true).should eq "€1.234.567,12"
      end

      it "inserts currency symbol after the amount when set to :after" do
        Money.us_dollar(1_000_000_000_12).format(symbol_first: false).should eq "1,000,000,000.12 $"
      end
    end

    describe ":symbol_before_without_space option" do
      it "does not insert space between currency symbol and amount when set to true" do
        Money.euro(1_234_567_12).format(symbol_first: true, symbol_before_without_space: true).should eq "€1.234.567,12"
      end

      it "inserts space between currency symbol and amount when set to false" do
        Money.euro(1_234_567_12).format(symbol_first: true, symbol_before_without_space: false).should eq "€ 1.234.567,12"
      end

      it "defaults to true" do
        Money.euro(1_234_567_12).format(symbol_first: true).should eq "€1.234.567,12"
      end
    end

    describe ":symbol_after_without_space option" do
      it "does not insert space between amount and currency symbol when set to true" do
        Money.euro(1_234_567_12).format(symbol_first: false, symbol_after_without_space: true).should eq "1.234.567,12€"
      end

      it "inserts space between amount and currency symbol when set to false" do
        Money.euro(1_234_567_12).format(symbol_first: false, symbol_after_without_space: false).should eq "1.234.567,12 €"
      end

      it "defaults to false" do
        Money.euro(1_234_567_12).format(symbol_first: false).should eq "1.234.567,12 €"
      end
    end

    describe ":sign_positive option" do
      context "(sign_positive: true, symbol_first: true)" do
        it "works as documented" do
          Money.us_dollar(0).format(sign_positive: true, symbol_first: true).should eq "$0.00"
          Money.us_dollar(100000).format(sign_positive: true, symbol_first: true).should eq "+$1,000.00"
          Money.us_dollar(-100000).format(sign_positive: true, symbol_first: true).should eq "-$1,000.00"
        end
      end

      context "(sign_positive: true, symbol_first: false)" do
        it "works as documented" do
          Money.us_dollar(0).format(sign_positive: true, symbol_first: false).should eq "0.00 $"
          Money.us_dollar(100000).format(sign_positive: true, symbol_first: false).should eq "+1,000.00 $"
          Money.us_dollar(100000).format(sign_positive: true, symbol_first: nil).should eq "+1,000.00 $"
          Money.us_dollar(-100000).format(sign_positive: true, symbol_first: false).should eq "-1,000.00 $"
          Money.us_dollar(-100000).format(sign_positive: true, symbol_first: nil).should eq "-1,000.00 $"
        end
      end

      context "(sign_positive: false, symbol_first: true)" do
        it "works as documented" do
          Money.us_dollar(100000).format(sign_positive: false, symbol_first: true).should eq "$1,000.00"
          Money.us_dollar(-100000).format(sign_positive: false, symbol_first: true).should eq "-$1,000.00"
        end
      end

      context "(sign_positive: false, symbol_first: false)" do
        it "works as documented" do
          Money.us_dollar(100000).format(sign_positive: false, symbol_first: false).should eq "1,000.00 $"
          Money.us_dollar(100000).format(sign_positive: false, symbol_first: nil).should eq "1,000.00 $"
          Money.us_dollar(-100000).format(sign_positive: false, symbol_first: false).should eq "-1,000.00 $"
          Money.us_dollar(-100000).format(sign_positive: false, symbol_first: nil).should eq "-1,000.00 $"
        end
      end
    end

    describe ":drop_trailing_zeros option" do
      context "(drop_trailing_zeros: true)" do
        it "works as documented" do
          Money.new(89000, "BTC").format(drop_trailing_zeros: true, symbol: false).should eq "0.00089"
          Money.new(100089000, "BTC").format(drop_trailing_zeros: true, symbol: false).should eq "1.00089"
          Money.new(100000000, "BTC").format(drop_trailing_zeros: true, symbol: false).should eq "1"
          Money.new(110, "AUD").format(drop_trailing_zeros: true, symbol: false).should eq "1.1"
        end
      end

      context "(drop_trailing_zeros: false)" do
        it "works as documented" do
          Money.new(89000, "BTC").format(drop_trailing_zeros: false, symbol: false).should eq "0.00089000"
          Money.new(100089000, "BTC").format(drop_trailing_zeros: false, symbol: false).should eq "1.00089000"
          Money.new(100000000, "BTC").format(drop_trailing_zeros: false, symbol: false).should eq "1.00000000"
          Money.new(110, "AUD").format(drop_trailing_zeros: false, symbol: false).should eq "1.10"
        end
      end
    end

    context "when the monetary value is 0" do
      it "returns '$0.00' when :display_free is false or not given" do
        Money.us_dollar(0).format.should eq "$0.00"
        Money.us_dollar(0).format(display_free: false).should eq "$0.00"
        Money.us_dollar(0).format(display_free: nil).should eq "$0.00"
      end

      it "returns the value specified by :display_free if it's a string-like object" do
        Money.us_dollar(0).format(display_free: "gratis").should eq "gratis"
      end
    end
  end

  context "custom currencies with 4 decimal places" do
    it "respects custom subunit to unit, decimal and thousands separator" do
      with_registered_currency(bar_currency, eu4_currency) do
        Money.new(4, "BAR").format.should eq "$0.0004"
        Money.new(4, "EU4").format.should eq "€0,0004"

        Money.new(24, "BAR").format.should eq "$0.0024"
        Money.new(24, "EU4").format.should eq "€0,0024"

        Money.new(324, "BAR").format.should eq "$0.0324"
        Money.new(324, "EU4").format.should eq "€0,0324"

        Money.new(5324, "BAR").format.should eq "$0.5324"
        Money.new(5324, "EU4").format.should eq "€0,5324"

        Money.new(65324, "BAR").format.should eq "$6.5324"
        Money.new(65324, "EU4").format.should eq "€6,5324"

        Money.new(865324, "BAR").format.should eq "$86.5324"
        Money.new(865324, "EU4").format.should eq "€86,5324"

        Money.new(1865324, "BAR").format.should eq "$186.5324"
        Money.new(1865324, "EU4").format.should eq "€186,5324"

        Money.new(33310034, "BAR").format.should eq "$3,331.0034"
        Money.new(33310034, "EU4").format.should eq "€3.331,0034"

        Money.new(88833310034, "BAR").format.should eq "$8,883,331.0034"
        Money.new(88833310034, "EU4").format.should eq "€8.883.331,0034"
      end
    end
  end
end
