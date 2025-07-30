require "../spec_helper"

describe Money::Constructors do
  describe ".new" do
    context "given the initializing value is an integer" do
      it "stores the integer as the number of cents" do
        Money.new(1).cents.should eq 1
      end
    end

    context "given the initializing value is a float" do
      context "and the value is Infinity" do
        it do
          expect_raises(ArgumentError) { Money.new(-Float32::INFINITY) }
          expect_raises(ArgumentError) { Money.new(-Float64::INFINITY) }
          expect_raises(ArgumentError) { Money.new(Float32::INFINITY) }
          expect_raises(ArgumentError) { Money.new(Float64::INFINITY) }
        end
      end

      context "and the value is NaN" do
        it do
          expect_raises(ArgumentError) { Money.new(Float32::NAN) }
          expect_raises(ArgumentError) { Money.new(Float64::NAN) }
        end
      end

      context "and the value is 1.00" do
        it { Money.new(1.00).should eq Money.new(1.0) }
      end

      context "and the value is 1.01" do
        it { Money.new(1.01).should eq Money.new(1.01) }
      end

      context "and the value is 1.007" do
        it { Money.new(1.007).should eq Money.new(1.01) }
      end

      context "and the value is 1.50" do
        it { Money.new(1.50).should eq Money.new(1.5) }
      end
    end

    context "given the initializing value is a rational" do
      it { Money.new(BigRational.new(1)).should eq Money.new(1.0) }
    end

    context "given there's no amount provided" do
      it "should have zero amount" do
        Money.new.amount.should eq 0
      end
    end

    context "given a currency is not provided" do
      it "should have the default currency" do
        Money.new.currency.should be Money.default_currency
      end
    end

    context "given a currency is provided" do
      context "and the currency is NZD" do
        it "should have NZD currency" do
          Money.new(currency: "NZD").currency.should be Money::Currency.find("NZD")
        end
      end
    end

    context "given a exchange is not provided" do
      it "should return the default exchange" do
        Money.new.exchange.should be Money.default_exchange
      end
    end

    context "given a exchange is provided" do
      exchange = Money::Currency::Exchange::SingleCurrency.new

      it "should return given exchange" do
        Money.new(exchange: exchange).exchange.should be exchange
      end
    end
  end

  describe ".from_amount" do
    it "accepts numeric values" do
      Money.from_amount(1, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount(1.0, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount(1.to_big_d, "USD").should eq Money.new(1_00, "USD")
    end

    it "converts given amount to subunits according to currency" do
      Money.from_amount(1, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount(1, "TND").should eq Money.new(1_000, "TND")
      Money.from_amount(1, "JPY").should eq Money.new(1, "JPY")
    end

    it "rounds the given amount to subunits" do
      Money.from_amount(4.444, "USD").amount.should eq 4.44.to_big_d
      Money.from_amount(5.555, "USD").amount.should eq 5.56.to_big_d
      Money.from_amount(444.4, "JPY").amount.should eq 444.to_big_d
      Money.from_amount(555.5, "JPY").amount.should eq 556.to_big_d
    end

    it "does not round the given amount when .infinite_precision? is set" do
      Money.with_infinite_precision do
        Money.from_amount(4.444, "USD").amount.should eq 4.444.to_big_d
        Money.from_amount(5.555, "USD").amount.should eq 5.555.to_big_d
        Money.from_amount(444.4, "JPY").amount.should eq 444.4.to_big_d
        Money.from_amount(555.5, "JPY").amount.should eq 555.5.to_big_d
      end
    end

    it "uses the default currency when no currency is provided" do
      Money.from_amount(1).currency.should eq Money.default_currency
    end

    it "accepts an optional currency" do
      Money::Currency.find("JPY").tap do |jpy|
        Money.from_amount(1, jpy).currency.should be jpy
        Money.from_amount(1, "JPY").currency.should be jpy
      end
    end
  end

  describe ".from_fractional" do
    it "accepts numeric values" do
      Money.from_fractional(1, "USD").should eq Money.new(1, "USD")
      Money.from_fractional(1.0, "USD").should eq Money.new(1, "USD")
      Money.from_fractional(1.to_big_d, "USD").should eq Money.new(1, "USD")
    end

    it "uses the default currency when no currency is provided" do
      Money.from_fractional(1).currency.should eq Money.default_currency
    end

    it "accepts an optional currency" do
      Money::Currency.find("JPY").tap do |jpy|
        Money.from_fractional(1, jpy).currency.should be jpy
        Money.from_fractional(1, "JPY").currency.should be jpy
      end
    end
  end

  describe ".zero" do
    it "creates a new Money object of 0 cents" do
      Money.zero.should eq Money.new(0)
    end

    it "uses default Currency::Exchange object" do
      Money.zero.exchange.should be Money.default_exchange
    end

    it "uses given Currency object" do
      Money::Currency.find("EUR").tap do |currency|
        Money.zero(currency: currency).currency.should be currency
      end
    end

    it "uses given Currency::Exchange object" do
      Money::Currency::Exchange::SingleCurrency.new.tap do |exchange|
        Money.zero(exchange: exchange).exchange.should be exchange
      end
    end
  end

  describe ".us_dollar" do
    it "creates a new Money object of the given value in USD" do
      Money.us_dollar(50).should eq Money.new(50, "USD")
    end
  end

  describe ".euro" do
    it "creates a new Money object of the given value in EUR" do
      Money.euro(50).should eq Money.new(50, "EUR")
    end
  end

  describe ".bitcoin" do
    it "creates a new Money object of the given value in BTC" do
      Money.bitcoin(50).should eq Money.new(50, "BTC")
    end
  end
end
