require "./spec_helper"

describe Money do
  describe ".new" do
    context "given the initializing value is an integer" do
      it "stores the integer as the number of cents" do
        Money.new(1).cents.should eq 1
      end
    end

    context "given the initializing value is a float" do
      context "and the value is 1.00" do
        it { Money.new(1.00).should eq Money.new(1) }
      end

      context "and the value is 1.01" do
        it { Money.new(1.01).should eq Money.new(1) }
      end

      context "and the value is 1.50" do
        it { Money.new(1.50).should eq Money.new(2) }
      end
    end

    context "given the initializing value is a rational" do
      it { Money.new(BigRational.new(1)).should eq Money.new(1) }
    end

    context "given a currency is not provided" do
      it "should have the default currency" do
        Money.new(1).currency.should eq Money.default_currency
      end
    end

    context "given a currency is provided" do
      context "and the currency is NZD" do
        it "should have NZD currency" do
          Money.new(1, "NZD").currency.should eq Money::Currency.find("NZD")
        end
      end

      context "and the currency is nil" do
        it "should have the default currency" do
          Money.new(1).currency.should eq Money.default_currency
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
      Money.from_amount(4.444, "USD").amount.should eq "4.44".to_big_d
      Money.from_amount(5.555, "USD").amount.should eq "5.56".to_big_d
      Money.from_amount(444.4, "JPY").amount.should eq "444".to_big_d
      Money.from_amount(555.5, "JPY").amount.should eq "556".to_big_d
    end

    it "accepts an optional currency" do
      Money.from_amount(1).currency.should eq Money.default_currency
      Money::Currency["JPY"].tap do |jpy|
        Money.from_amount(1, jpy).currency.should eq jpy
        Money.from_amount(1, "JPY").currency.should eq jpy
      end
    end

    context "given a currency is provided" do
      context "and the currency is nil" do
        it "should have the default currency" do
          Money.from_amount(1).currency.should eq Money.default_currency
        end
      end
    end
  end

  describe "#fractional" do
    it "returns the amount in fractional unit" do
      Money.new(1_00).fractional.should eq 1_00
    end

    it "stores fractional as an Int64 regardless of what is passed into the constructor" do
      m = Money.new(100)
      m.fractional.should eq 100.0.to_big_d
      m.fractional.should be_a(Int64)
    end

    context "loading a serialized Money via JSON" do
      money = Money.from_json(%q({
        "fractional": 3300,
        "currency": "EUR"
      }))

      it "loads fractional" do
        money.fractional.should eq 33_00
      end

      it "loads currency by string" do
        money.currency.should eq Money::Currency["EUR"]
      end
    end
  end

  describe "#nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      money = Money.new(2350, "AED")
      money.nearest_cash_value.should eq 2350

      money = Money.new(-2350, "AED")
      money.nearest_cash_value.should eq(-2350)

      money = Money.new(2213, "AED")
      money.nearest_cash_value.should eq 2225

      money = Money.new(-2213, "AED")
      money.nearest_cash_value.should eq(-2225)

      money = Money.new(2212, "AED")
      money.nearest_cash_value.should eq 2200

      money = Money.new(-2212, "AED")
      money.nearest_cash_value.should eq(-2200)

      money = Money.new(178, "CHF")
      money.nearest_cash_value.should eq 180

      money = Money.new(-178, "CHF")
      money.nearest_cash_value.should eq(-180)

      money = Money.new(177, "CHF")
      money.nearest_cash_value.should eq 175

      money = Money.new(-177, "CHF")
      money.nearest_cash_value.should eq(-175)

      money = Money.new(175, "CHF")
      money.nearest_cash_value.should eq 175

      money = Money.new(-175, "CHF")
      money.nearest_cash_value.should eq(-175)

      money = Money.new(299, "USD")
      money.nearest_cash_value.should eq 299

      money = Money.new(-299, "USD")
      money.nearest_cash_value.should eq(-299)

      money = Money.new(300, "USD")
      money.nearest_cash_value.should eq 300

      money = Money.new(-300, "USD")
      money.nearest_cash_value.should eq(-300)

      money = Money.new(301, "USD")
      money.nearest_cash_value.should eq 301

      money = Money.new(-301, "USD")
      money.nearest_cash_value.should eq(-301)
    end

    it "raises an exception if smallest denomination is not defined" do
      money = Money.new(100, "XAG")
      expect_raises(Money::UndefinedSmallestDenominationError) { money.nearest_cash_value }
    end

    it "returns an Int64" do
      money = Money.new(100, "EUR")
      money.nearest_cash_value.should be_a Int64
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
      Money.new(100_37).amount.should eq 100.37
    end

    it "produces a BigDecimal" do
      Money.new(1_00).amount.should be_a BigDecimal
    end
  end

  describe "#currency" do
    it "returns the currency object" do
      Money.new(1_00, "USD").currency.should eq Money::Currency.find("USD")
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

    it "can be used to return the intersection of Money object arrays" do
      intersection = [Money.new(1_00, "EUR"), Money.new(1_00, "USD")] & [Money.new(1_00, "EUR")]
      intersection.should eq [Money.new(1_00, "EUR")]
    end
  end

  describe "#to_big_d" do
    it "works as documented" do
      decimal = Money.new(10_00).to_big_d
      decimal.should be_a(BigDecimal)
      decimal.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      decimal = Money.new(10_00, "BHD").to_big_d
      decimal.should be_a(BigDecimal)
      decimal.should eq 1.0
    end

    it "works with float :subunit_to_unit currency property" do
      money = Money.new(10_00, "BHD")
      # allow(money.currency).should receive(:subunit_to_unit).and_return(1000.0)

      decimal = money.to_big_d
      decimal.should be_a(BigDecimal)
      decimal.should eq 1.0
    end
  end

  describe "#to_f" do
    it "works as documented" do
      Money.new(10_00).to_f.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      Money.new(10_00, "BHD").to_f.should eq 1.0
    end
  end

  describe "#allocate" do
    it "takes no action when one gets all" do
      Money.us_dollar(5).allocate({1.0}).should eq [Money.us_dollar(5)]
    end

    it "keeps currencies intact" do
      Money.us_dollar(5).allocate({1}).should eq [Money.us_dollar(5)]
    end

    it "does not lose pennies" do
      moneys = Money.us_dollar(5).allocate({0.3, 0.7})
      moneys[0].should eq Money.us_dollar(2)
      moneys[1].should eq Money.us_dollar(3)
    end

    it "does not lose pennies" do
      moneys = Money.us_dollar(100).allocate({0.333, 0.333, 0.333})
      moneys[0].cents.should eq 34
      moneys[1].cents.should eq 33
      moneys[2].cents.should eq 33
    end

    it "handles mixed split types" do
      splits = {BigRational.new(1, 4), 0.25, 0.25, BigDecimal.new("0.25")}
      moneys = Money.us_dollar(100).allocate(splits)
      moneys.each do |money|
        money.cents.should eq 25
      end
    end

    context "negative amount" do
      it "does not lose pennies" do
        moneys = Money.us_dollar(-100).allocate({0.333, 0.333, 0.333})

        moneys[0].cents.should eq(-34)
        moneys[1].cents.should eq(-33)
        moneys[2].cents.should eq(-33)
      end

      it "allocates the same way as positive amounts" do
        ratios = {0.6667, 0.3333}

        Money.us_dollar(10_00).allocate(ratios).map(&.fractional).should eq([6_67, 3_33])
        Money.us_dollar(-10_00).allocate(ratios).map(&.fractional).should eq([-6_67, -3_33])
      end
    end

    it "requires total to be less then 1" do
      expect_raises(ArgumentError) { Money.us_dollar(0.05).allocate({0.5, 0.6}) }
    end
  end

  describe "#split" do
    it "needs at least one party" do
      expect_raises(ArgumentError) { Money.us_dollar(1).split(0) }
      expect_raises(ArgumentError) { Money.us_dollar(1).split(-1) }
    end

    it "gives 1 cent to both people if we start with 2" do
      Money.us_dollar(2).split(2).should eq [Money.us_dollar(1), Money.us_dollar(1)]
    end

    it "may distribute no money to some parties if there isnt enough to go around" do
      Money.us_dollar(2).split(3).should eq [Money.us_dollar(1), Money.us_dollar(1), Money.us_dollar(0)]
    end

    it "does not lose pennies" do
      Money.us_dollar(5).split(2).should eq [Money.us_dollar(3), Money.us_dollar(2)]
    end

    it "splits a dollar" do
      moneys = Money.us_dollar(100).split(3)
      moneys[0].cents.should eq 34
      moneys[1].cents.should eq 33
      moneys[2].cents.should eq 33
    end
  end

  describe ".default_currency" do
    it "accepts a string" do
      with_default_currency("PLN") do
        Money.default_currency.should eq Money::Currency.find("PLN")
      end
    end

    it "accepts a symbol" do
      with_default_currency(:eur) do
        Money.default_currency.should eq Money::Currency.find(:eur)
      end
    end
  end
end
