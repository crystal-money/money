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

    it "parses currency from disambiguated symbol" do
      Money.parse?("0.00300101 ₿CH").should eq Money.from_amount(0.00300101, "BCH")
      Money.parse?("1000.00 A-UM").should eq Money.from_amount(1000, "MRO")
    end

    it "parses amount with thousands separators present" do
      Money.parse?("1,000 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1,000,000 USD").should eq Money.from_amount(1_000_000, "USD")
    end

    it "parses amount with thousands and decimal separators present" do
      Money.parse?("1,000.00 USD").should eq Money.from_amount(1_000, "USD")
      Money.parse?("1,000,000.00 USD").should eq Money.from_amount(1_000_000, "USD")
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
