require "./spec_helper"

describe Money::Currency do
  describe ".new" do
    it "initializes a new currency" do
      currency = Money::Currency.new(
        priority: 1,
        code: "XXX111",
        name: "Golden Doubloon",
        symbol: "%",
        symbol_first: false,
        subunit_to_unit: 100
      )
      currency.priority.should eq 1
      currency.code.should eq "XXX111"
      currency.name.should eq "Golden Doubloon"
      currency.symbol.should eq "%"
      currency.symbol_first?.should be_false
      currency.subunit_to_unit.should eq 100
    end

    it "raises ArgumentError for non-upper-case-alphanumeric :code values" do
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "foo",
          subunit_to_unit: 1
        )
      end
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "foo1",
          subunit_to_unit: 1
        )
      end
    end

    it "raises ArgumentError for non-positive :subunit_to_unit values" do
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "XXX",
          subunit_to_unit: 0
        )
      end
    end

    it "raises ArgumentError for non-positive :iso_numeric values" do
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "XXX",
          subunit_to_unit: 1,
          iso_numeric: 0
        )
      end
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "XXX",
          subunit_to_unit: 1,
          iso_numeric: -1
        )
      end
    end

    it "raises ArgumentError for non-positive :smallest_denomination values" do
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "XXX",
          subunit_to_unit: 1,
          smallest_denomination: 0
        )
      end
      expect_raises(ArgumentError) do
        Money::Currency.new(
          code: "XXX",
          subunit_to_unit: 1,
          smallest_denomination: -1
        )
      end
    end
  end

  describe ".wrap?" do
    it "returns nil for invalid ids" do
      Money::Currency.wrap?(:foo).should be_nil
    end
    it "returns passed object if object is Currency" do
      Money::Currency.wrap?(Money::Currency.find(:usd)).should be Money::Currency.find(:usd)
    end
    it "returns Currency object matching given id if object is String or Symbol" do
      Money::Currency.wrap?("USD").should be Money::Currency.find(:usd)
      Money::Currency.wrap?(:usd).should be Money::Currency.find(:usd)
    end
  end

  describe ".wrap" do
    it "raises UnknownCurrencyError for invalid ids" do
      expect_raises(Money::UnknownCurrencyError) { Money::Currency.wrap(:foo) }
    end
  end

  describe ".register" do
    it "registers a new currency" do
      currency = Money::Currency.new(
        priority: 1,
        code: "XXX",
        name: "Golden Doubloon",
        symbol: "%",
        symbol_first: false,
        subunit_to_unit: 100
      )
      with_registered_currency(currency) do
        new_currency = Money::Currency.find("XXX")
        new_currency.should_not be_nil
        new_currency.name.should eq "Golden Doubloon"
        new_currency.symbol.should eq "%"
        new_currency.decimal_places.should eq 2
      end
    end
  end

  describe ".unregister" do
    currency = Money::Currency.new(
      priority: 1,
      code: "XXX",
      name: "Golden Doubloon",
      symbol: "%",
      symbol_first: false,
      subunit_to_unit: 100
    )

    it "unregisters a currency" do
      Money::Currency.register(currency).should eq currency
      Money::Currency.find?("XXX").should_not be_nil # Sanity check
      Money::Currency.unregister("XXX").should eq currency
      Money::Currency.find?("XXX").should be_nil
    end

    it "returns true if the currency existed" do
      Money::Currency.register(currency).should eq currency
      Money::Currency.unregister(currency).should eq currency
      Money::Currency.unregister(currency).should be_nil
    end

    it "can be passed an ISO code as a string" do
      with_registered_currency(currency) do
        Money::Currency.unregister("XXX")
        Money::Currency.find?("XXX").should be_nil
      end
    end

    it "can be passed an ISO code as a symbol" do
      with_registered_currency(currency) do
        Money::Currency.unregister(:xxx)
        Money::Currency.find?(:xxx).should be_nil
      end
    end
  end

  describe ".reset!" do
    currency = Money::Currency.new(
      priority: 1,
      code: "XXX",
      name: "Golden Doubloon",
      symbol: "%",
      symbol_first: false,
      subunit_to_unit: 100
    )

    it "resets all registered currencies to their defaults" do
      Money::Currency.register(currency)
      Money::Currency.find?("XXX").should_not be_nil # Sanity check
      Money::Currency.reset!
      Money::Currency.find?("XXX").should be_nil
    end
  end

  describe "#<=>" do
    it "compares objects by priority" do
      Money::Currency.find(:cad).should be > Money::Currency.find(:usd)
      Money::Currency.find(:usd).should be < Money::Currency.find(:eur)
    end
  end

  describe "#==" do
    it "returns true if self === other" do
      currency = Money::Currency.find(:eur)
      currency.should eq currency
    end

    it "allows comparison with nil and returns false" do
      Money::Currency.find(:eur).should_not be_nil
    end
  end

  describe "#hash" do
    it "returns the same value for equal objects" do
      Money::Currency.find(:eur).hash.should eq Money::Currency.find(:eur).hash
      Money::Currency.find(:eur).hash.should_not eq Money::Currency.find(:usd).hash
    end

    it "can be used to return the intersection of Currency object arrays" do
      currencies = [Money::Currency.find(:eur), Money::Currency.find(:usd)]

      intersection = currencies & [Money::Currency.find(:eur)]
      intersection.should eq [Money::Currency.find(:eur)]
    end
  end

  describe "#to_s" do
    it "works as documented" do
      Money::Currency.find(:usd).to_s.should eq "USD"
      Money::Currency.find(:eur).to_s.should eq "EUR"
    end
  end

  describe "#symbol" do
    it "works as documented" do
      Money::Currency.find(:usd).symbol.should eq "$"
      Money::Currency.find(:azn).symbol.should eq "\u20BC"
    end
  end

  describe "#iso?" do
    it "works as documented" do
      Money::Currency.find(:usd).iso?.should be_true
      Money::Currency.find(:btc).iso?.should be_false
    end
  end

  describe "#type" do
    it "works as documented" do
      Money::Currency.find(:xts).type.should be_nil
      Money::Currency.find(:xau).type.should eq Money::Currency::Type::Metal
      Money::Currency.find(:usd).type.should eq Money::Currency::Type::Fiat
      Money::Currency.find(:btc).type.should eq Money::Currency::Type::Crypto
    end
  end

  describe "#metal?" do
    it "works as documented" do
      Money::Currency.find(:xts).metal?.should be_false
      Money::Currency.find(:xau).metal?.should be_true
      Money::Currency.find(:usd).metal?.should be_false
      Money::Currency.find(:btc).metal?.should be_false
    end
  end

  describe "#fiat?" do
    it "works as documented" do
      Money::Currency.find(:xts).fiat?.should be_false
      Money::Currency.find(:xau).fiat?.should be_false
      Money::Currency.find(:usd).fiat?.should be_true
      Money::Currency.find(:btc).fiat?.should be_false
    end
  end

  describe "#crypto?" do
    it "works as documented" do
      Money::Currency.find(:xts).crypto?.should be_false
      Money::Currency.find(:xau).crypto?.should be_false
      Money::Currency.find(:usd).crypto?.should be_false
      Money::Currency.find(:btc).crypto?.should be_true
    end
  end

  describe "#cents_based?" do
    it "returns true for cents based currency" do
      Money::Currency.find(:usd).cents_based?.should be_true
    end

    it "returns false if the currency is not cents based" do
      Money::Currency.find(:clp).cents_based?.should be_false
    end
  end

  describe "#exponent" do
    it "conforms to iso 4217" do
      Money::Currency.find(:jpy).exponent.should eq 0
      Money::Currency.find(:usd).exponent.should eq 2
      Money::Currency.find(:iqd).exponent.should eq 3
    end
  end

  describe "#decimal_places" do
    it "proper places for known currency" do
      Money::Currency.find(:mru).decimal_places.should eq 1
      Money::Currency.find(:usd).decimal_places.should eq 2
    end
  end
end
