require "../spec_helper"

describe Money::Parse do
  describe ".parse?" do
    it "parses symbol as prefix" do
      Money.parse?("$10").should eq Money.from_amount(10.0, "USD")
      Money.parse?("+$10").should eq Money.from_amount(10.0, "USD")
      Money.parse?("$1.23").should eq Money.from_amount(1.23, "USD")
      Money.parse?("+$1.23").should eq Money.from_amount(1.23, "USD")
      Money.parse?("-$1.23").should eq Money.from_amount(-1.23, "USD")
    end

    it "parses symbol as suffix" do
      Money.parse?("10$").should eq Money.from_amount(10.0, "USD")
      Money.parse?("+10$").should eq Money.from_amount(10.0, "USD")
      Money.parse?("1.23$").should eq Money.from_amount(1.23, "USD")
      Money.parse?("+1.23$").should eq Money.from_amount(1.23, "USD")
      Money.parse?("-1.23$").should eq Money.from_amount(-1.23, "USD")

      Money.parse?("1.23 zł").should eq Money.from_amount(1.23, "PLN")
      Money.parse?("+1.23 zł").should eq Money.from_amount(1.23, "PLN")
      Money.parse?("1.23zł").should eq Money.from_amount(1.23, "PLN")
      Money.parse?("-1.23zł").should eq Money.from_amount(-1.23, "PLN")
    end

    it "parses currency code after amount" do
      Money.parse?("10 USD").should eq Money.from_amount(10.0, "USD")
      Money.parse?("+10 USD").should eq Money.from_amount(10.0, "USD")
      Money.parse?("1.23 USD").should eq Money.from_amount(1.23, "USD")
      Money.parse?("+1.23 USD").should eq Money.from_amount(1.23, "USD")
      Money.parse?("-1.23 USD").should eq Money.from_amount(-1.23, "USD")

      Money.parse?("0.00300101 BTC").should eq Money.from_amount(0.00300101, "BTC")
      Money.parse?("+0.00300101 BTC").should eq Money.from_amount(0.00300101, "BTC")
      Money.parse?("-0.00300101 BTC").should eq Money.from_amount(-0.00300101, "BTC")
    end

    it "parses currency code in case insensitive manner" do
      Money.parse?("10 pln").should eq Money.from_amount(10.0, "PLN")
      Money.parse?("10 uSd").should eq Money.from_amount(10.0, "USD")
    end

    it "parses currency from disambiguated symbol" do
      Money.parse?("0.00300101 ₿CH").should eq Money.from_amount(0.00300101, "BCH")
      Money.parse?("1000.00 A-UM").should eq Money.from_amount(1000, "MRO")
    end

    it "parses amount with thousands separators present" do
      Money.parse?("1 000 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1,000 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1.000 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1.000 EUR").should eq Money.from_amount(1_000, "EUR")
      Money.parse?("10,000 USD").should eq Money.from_amount(10_000, "USD")
      Money.parse?("100,000 USD").should eq Money.from_amount(100_000, "USD")
      Money.parse?("100.000 USD").should eq Money.from_amount(100_000, "USD")
      Money.parse?("1_000_000 USD").should eq Money.from_amount(1_000_000, "USD")
      Money.parse?("1,000,000 USD").should eq Money.from_amount(1_000_000, "USD")
      Money.parse?("1.000.000 USD").should eq Money.from_amount(1_000_000, "USD")
    end

    it "parses amount with decimal separators present" do
      Money.parse?("1000.5 USD").should eq Money.from_amount(1_000.5, "USD")
      Money.parse?("1000,5 USD").should eq Money.from_amount(1_000.5, "USD")
      Money.parse?("1000.22 USD").should eq Money.from_amount(1_000.22, "USD")
      Money.parse?("1000,22 USD").should eq Money.from_amount(1_000.22, "USD")
      Money.parse?("100.003 BTC").should eq Money.from_amount(100.003, "BTC")
      Money.parse?("0.003 BTC").should eq Money.from_amount(0.003, "BTC")
    end

    it "parses amount with thousands and decimal separators present" do
      Money.parse?("1_000.22 USD").should eq Money.from_amount(1_000.22, "USD")
      Money.parse?("1,000.22 USD").should eq Money.from_amount(1_000.22, "USD")
      Money.parse?("1.000,22 USD").should eq Money.from_amount(1_000.22, "USD")
      Money.parse?("1_000_000.22 USD").should eq Money.from_amount(1_000_000.22, "USD")
      Money.parse?("1,000,000.22 USD").should eq Money.from_amount(1_000_000.22, "USD")
      Money.parse?("1.000.000,22 USD").should eq Money.from_amount(1_000_000.22, "USD")
    end

    it "parses amount with `_` as thousands separator" do
      Money.parse?("1_000.00 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1_000_000 USD").should eq Money.from_amount(1_000_000, "USD")
    end

    it "parses amount with ` ` as thousands separator" do
      Money.parse?("1 000.00 PLN").should eq Money.from_amount(1_000, "PLN")
      Money.parse?("1 000 000 PLN").should eq Money.from_amount(1_000_000, "PLN")
    end

    it "returns nil when passed an invalid string" do
      Money.parse?("10").should be_nil
      Money.parse?("-10").should be_nil
      Money.parse?("1.23").should be_nil
      Money.parse?("+10x$").should be_nil
      Money.parse?("10 foo").should be_nil
      Money.parse?("foo").should be_nil
      Money.parse?("foo 10").should be_nil
      Money.parse?("-foo").should be_nil
    end

    context "when :allow_ambiguous is true (default)" do
      it "returns a first matching currency for ambiguous values" do
        Money.parse?("$10.00").should eq Money.new(10_00, "USD")
      end
    end

    context "when :allow_ambiguous is false" do
      it "returns nil for ambiguous values" do
        Money.parse?("$10.00", allow_ambiguous: false).should be_nil
      end
    end
  end

  describe ".parse" do
    it "raises when passed an invalid string" do
      expect_raises(Money::Parse::Error, /foo/) { Money.parse("foo") }
      expect_raises(Money::Parse::Error, /foo/) { Money.parse("foo 10") }
      expect_raises(Money::Parse::Error, /foo/) { Money.parse("10 foo") }
      expect_raises(Money::Parse::Error, /foo/) { Money.parse("-foo") }
      expect_raises(Money::Parse::Error) { Money.parse("10+foo") }
      expect_raises(Money::Parse::Error) { Money.parse("10+$") }
    end
  end
end
