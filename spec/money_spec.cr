require "./spec_helper"

ROUNDING_CONVERSIONS = {
  Number::RoundingMode::TO_ZERO => [
    {10.885, 10.88},
  ],
  Number::RoundingMode::TIES_EVEN => [
    {10.885, 10.88},
  ],
  Number::RoundingMode::TIES_AWAY => [
    {10.885, 10.89},
  ],
}

describe Money do
  describe ".new" do
    context "given the initializing value is an integer" do
      it "stores the integer as the number of cents" do
        Money.new(1).cents.should eq 1
      end
    end

    context "given the initializing value is a float" do
      context "and the value is Infinity" do
        it do
          expect_raises(ArgumentError) { Money.new(-Float64::INFINITY) }
          expect_raises(ArgumentError) { Money.new(Float64::INFINITY) }
        end
      end

      context "and the value is NaN" do
        it do
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
        Money.zero.currency.should be Money.default_currency
      end
    end

    context "given a currency is provided" do
      context "and the currency is NZD" do
        it "should have NZD currency" do
          Money.new(1, "NZD").currency.should be Money::Currency.find("NZD")
        end
      end
    end

    context "given a bank is not provided" do
      it "should return the default bank" do
        Money.zero.bank.should be Money.default_bank
      end
    end

    context "given a bank is provided" do
      bank = Money::Bank::SingleCurrency.new

      it "should return given bank" do
        Money.new(1, "USD", bank).bank.should be bank
      end
    end
  end

  describe ".with_rounding_mode" do
    ROUNDING_CONVERSIONS.each do |mode, values|
      values.each do |(value, expected)|
        it "sets `Money.rounding_mode` to `#{mode}` " \
           "within the yielded block and rounds #{value} to #{expected}" do
          prev_rounding_mode = Money.rounding_mode
          begin
            Money.with_rounding_mode(mode) do
              Money.new(value, "USD").round(2).should eq Money.new(expected, "USD")
              Money.new(value, "USD").amount.should eq expected.to_big_d
              Money.new(value, "USD")
                .rounded_to_nearest_cash_value
                .should eq Money.new(expected, "USD")
            end
          ensure
            Money.rounding_mode.should eq prev_rounding_mode
          end
        end
      end
    end
  end

  describe ".disallow_currency_conversions!" do
    it "disallows conversions when doing money arithmetic" do
      with_default_bank do
        Money.disallow_currency_conversion!

        expect_raises(Money::DifferentCurrencyError) do
          Money.new(100, "USD") + Money.new(100, "EUR")
        end
      end
    end
  end

  describe ".from_amount" do
    it "accepts numeric values" do
      Money.from_amount(1, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount(1.0, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount("1".to_big_d, "USD").should eq Money.new(1_00, "USD")
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
      with_infinite_precision(true) do
        Money.from_amount(4.444, "USD").amount.should eq 4.444.to_big_d
        Money.from_amount(5.555, "USD").amount.should eq 5.555.to_big_d
        Money.from_amount(444.4, "JPY").amount.should eq 444.4.to_big_d
        Money.from_amount(555.5, "JPY").amount.should eq 555.5.to_big_d
      end
    end

    it "accepts an optional currency" do
      Money.from_amount(1).currency.should eq Money.default_currency
      Money::Currency["JPY"].tap do |jpy|
        Money.from_amount(1, jpy).currency.should be jpy
        Money.from_amount(1, "JPY").currency.should be jpy
      end
    end

    context "given a currency is provided" do
      context "and the currency is nil" do
        it "should have the default currency" do
          Money.from_amount(1).currency.should be Money.default_currency
        end
      end
    end
  end

  describe "#fractional" do
    it "returns the amount in fractional unit" do
      money = Money.new(1_00)
      money.fractional.should eq 1_00
      money.fractional.should be_a BigInt
    end

    context "loading a serialized Money via JSON" do
      money = Money.from_json(%q({
        "amount": "33.00",
        "currency": "EUR"
      }))

      it "loads fractional" do
        money.fractional.should eq 33_00
      end

      it "loads currency by string" do
        money.currency.should be Money::Currency["EUR"]
      end
    end
  end

  describe "#nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      sets = {
        {2350, "AED", 2350},
        {-2350, "AED", -2350},
        {2213, "AED", 2225},
        {-2213, "AED", -2225},
        {2212, "AED", 2200},
        {-2212, "AED", -2200},
        {178, "CHF", 180},
        {-178, "CHF", -180},
        {177, "CHF", 175},
        {-177, "CHF", -175},
        {175, "CHF", 175},
        {-175, "CHF", -175},
        {299, "USD", 299},
        {-299, "USD", -299},
        {300, "USD", 300},
        {-300, "USD", -300},
        {301, "USD", 301},
        {-301, "USD", -301},
      }
      sets.each do |(fractional, currency, expected)|
        Money.new(fractional, currency).nearest_cash_value.should eq expected
      end
    end

    it "raises an exception if smallest denomination is not defined" do
      money = Money.new(100, "XAG")
      expect_raises(Money::UndefinedSmallestDenominationError) do
        money.nearest_cash_value
      end
    end

    it "returns a BigInt" do
      Money.new(100, "EUR").nearest_cash_value.should be_a BigInt
    end
  end

  describe "#rounded_to_nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      Money.new(-2213, "AED").rounded_to_nearest_cash_value.cents.should eq -2225
    end
  end

  describe "#amount" do
    it "returns the amount of cents as dollars" do
      Money.new(1_00).amount.should eq 1
    end

    it "respects :subunit_to_unit currency property" do
      Money.new(1_00, "USD").amount.should eq 1
      Money.new(1_000, "TND").amount.should eq 1
      Money.new(1, "VUV").amount.should eq 1
      Money.new(1, "CLP").amount.should eq 1
    end

    it "does not lose precision" do
      Money.new(100_37).amount.should eq 100.37.to_big_d
    end

    it "produces a BigDecimal" do
      Money.zero.amount.should be_a BigDecimal
    end
  end

  describe "#currency" do
    it "returns the currency object" do
      Money.zero.currency.should be Money::Currency.find("USD")
    end
  end

  describe "#bank" do
    it "returns default Bank object" do
      Money.zero.bank.should be Money.default_bank
    end

    it "returns Bank object passed in #initialize" do
      Money::Bank::SingleCurrency.new.tap do |bank|
        Money.zero(bank: bank).bank.should be bank
      end
    end

    it "takes Bank object" do
      Money::Bank::SingleCurrency.new.tap do |bank|
        Money.zero.tap do |zero|
          zero.bank = bank
          zero.bank.should be bank
        end
      end
    end
  end

  describe "#hash=" do
    it "returns the same value for equal objects" do
      Money.new(1_00, "EUR").hash.should eq Money.new(1_00, "EUR").hash
      Money.new(2_00, "USD").hash.should eq Money.new(2_00, "USD").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(2_00, "EUR").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(1_00, "USD").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(2_00, "USD").hash
    end

    pending "can be used to return the intersection of Money object arrays" do
      intersection = [Money.new(1_00, "EUR"), Money.new(1_00, "USD")] & [Money.new(1_00, "EUR")]
      intersection.should eq [Money.new(1_00, "EUR")]
    end
  end

  describe ".default_currency" do
    it "accepts a string" do
      with_default_currency("PLN") do
        Money.default_currency.should be Money::Currency.find("PLN")
      end
    end

    it "accepts a symbol" do
      with_default_currency(:eur) do
        Money.default_currency.should be Money::Currency.find(:eur)
      end
    end
  end

  describe ".default_bank" do
    it "returns the Bank object" do
      Money.default_bank.should be_a Money::Bank
    end

    it "sets the value to the given Bank object" do
      bank = Money::Bank::SingleCurrency.new
      with_default_bank(bank) do
        Money.default_bank.should be bank
      end
    end
  end
end
