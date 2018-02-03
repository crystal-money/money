require "./spec_helper"

describe Money::Currency do
  describe ".wrap?" do
    it "returns nil if object is nil" do
      Money::Currency.wrap?(nil).should be_nil
    end
    it "returns passed object if object is Currency" do
      Money::Currency.wrap?(Money::Currency.find(:usd)).should eq Money::Currency.find(:usd)
    end
    it "returns Currency object matching given id if object is String or Symbol" do
      Money::Currency.wrap?("USD").should eq Money::Currency.find(:usd)
      Money::Currency.wrap?(:usd).should eq Money::Currency.find(:usd)
    end
  end

  describe ".wrap" do
    it "raises UnknownCurrencyError if object is nil" do
      expect_raises(Money::UnknownCurrencyError) { Money::Currency.wrap(nil) }
    end
  end

  describe ".register" do
    it "registers a new currency" do
      currency = Money::Currency.from_json(%q({
        "priority": 1,
        "code": "XXX",
        "name": "Golden Doubloon",
        "symbol": "%",
        "symbol_first": false,
        "subunit_to_unit": 100
      }))
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
    currency = Money::Currency.from_json(%q({
      "priority": 1,
      "code": "XXX",
      "name": "Golden Doubloon",
      "symbol": "%",
      "symbol_first": false,
      "subunit_to_unit": 100
    }))

    it "unregisters a currency" do
      Money::Currency.register(currency)
      Money::Currency.find?("XXX").should_not be_nil # Sanity check
      Money::Currency.unregister(currency)
      Money::Currency.find?("XXX").should be_nil
    end

    it "returns true if the currency existed" do
      Money::Currency.register(currency)
      Money::Currency.unregister(currency).should be_truthy
      Money::Currency.unregister(currency).should be_falsey
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

    it "returns true if the id is equal ignorning case" do
      Money::Currency.find(:eur).should eq Money::Currency.find(:eur)
      Money::Currency.find(:eur).should eq Money::Currency.find(:EUR)
      Money::Currency.find(:eur).should_not eq Money::Currency.find(:usd)
    end

    it "allows direct comparison of currencies and symbols/strings" do
      Money::Currency.find(:eur).should eq "eur"
      Money::Currency.find(:eur).should eq "EUR"
      Money::Currency.find(:eur).should eq :eur
      Money::Currency.find(:eur).should eq :EUR
      Money::Currency.find(:eur).should_not eq "usd"
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
      intersection = [Money::Currency.find(:eur), Money::Currency.find(:usd)] & [Money::Currency.find(:eur)]
      intersection.should eq [Money::Currency.find(:eur)]
    end
  end

  describe "#to_s" do
    it "works as documented" do
      Money::Currency.find(:usd).to_s.should eq("USD")
      Money::Currency.find(:eur).to_s.should eq("EUR")
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

  describe "#exponent" do
    it "conforms to iso 4217" do
      Money::Currency.find(:jpy).exponent.should eq 0
      Money::Currency.find(:usd).exponent.should eq 2
      Money::Currency.find(:iqd).exponent.should eq 3
    end
  end

  describe "#decimal_places" do
    it "proper places for known currency" do
      Money::Currency.find(:mro).decimal_places.should eq 1
      Money::Currency.find(:usd).decimal_places.should eq 2
    end
  end
end
