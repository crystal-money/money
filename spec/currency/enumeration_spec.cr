require "../spec_helper"

describe Money::Currency::Enumeration do
  foo_currency = Money::Currency.new(
    priority: 1,
    code: "FOO",
    iso_numeric: 840,
    name: "United States Dollar",
    symbol: "$",
    subunit: "Cent",
    subunit_to_unit: 1000,
    symbol_first: true,
    decimal_mark: ".",
    thousands_separator: ",",
    smallest_denomination: 1,
  )

  describe ".find" do
    it "returns currency matching given code" do
      with_registered_currency(foo_currency) do
        Money::Currency.find(:foo).should be foo_currency
        Money::Currency.find(:FOO).should be foo_currency
        Money::Currency.find("foo").should be foo_currency
        Money::Currency.find("FOO").should be foo_currency
      end
    end

    it "lookups data from loaded config" do
      us_dollar = Money::Currency.find("USD")
      us_dollar.priority.should eq 1
      us_dollar.code.should eq "USD"
      us_dollar.iso_numeric.should eq 840
      us_dollar.iso?.should be_true
      us_dollar.name.should eq "United States Dollar"
      us_dollar.decimal_mark.should eq "."
      us_dollar.thousands_separator.should eq ","
      us_dollar.smallest_denomination.should eq 1
    end

    it "caches instances" do
      Money::Currency.find("USD").should be Money::Currency.registry["USD"]
    end

    it "raises NotFoundError with unknown currency" do
      expect_raises(Money::Currency::NotFoundError, "Unknown currency: zZz") do
        Money::Currency.find("zZz")
      end
    end

    it "returns old object for the same :key" do
      Money::Currency.find("USD").should be Money::Currency.find("USD")
      Money::Currency.find("USD").should be Money::Currency.find(:usd)
      Money::Currency.find("USD").should be Money::Currency.find(:USD)
      Money::Currency.find("USD").should be Money::Currency.find("usd")
      Money::Currency.find("USD").should be Money::Currency.find("Usd")
    end

    it "returns new object for the different :key" do
      Money::Currency.find("USD").should_not be Money::Currency.find("EUR")
    end
  end

  describe ".find?" do
    it "returns currency matching given code" do
      with_registered_currency(foo_currency) do
        Money::Currency.find?(:foo).should be foo_currency
        Money::Currency.find?(:FOO).should be foo_currency
        Money::Currency.find?("foo").should be foo_currency
        Money::Currency.find?("FOO").should be foo_currency
      end
    end

    it "returns nil unless currency matches given code" do
      Money::Currency.find?("ZZZ").should be_nil
    end
  end

  describe ".[]?" do
    it "returns nil for invalid codes" do
      Money::Currency[:foo]?.should be_nil
    end

    it "returns passed object if object is Currency" do
      Money::Currency[Money::Currency.find(:usd)]?.should be Money::Currency.find(:usd)
    end

    it "returns Currency object matching given code if object is String or Symbol" do
      Money::Currency["USD"]?.should be Money::Currency.find(:usd)
      Money::Currency[:usd]?.should be Money::Currency.find(:usd)
    end
  end

  describe ".[]" do
    it "raises NotFoundError for invalid codes" do
      expect_raises(Money::Currency::NotFoundError) { Money::Currency[:foo] }
    end

    it "returns passed object if object is Currency" do
      Money::Currency[Money::Currency.find(:usd)].should be Money::Currency.find(:usd)
    end

    it "returns Currency object matching given code if object is String or Symbol" do
      Money::Currency["USD"].should be Money::Currency.find(:usd)
      Money::Currency[:usd].should be Money::Currency.find(:usd)
    end
  end

  describe ".all" do
    it "returns an array of currencies" do
      Money::Currency.all.should contain Money::Currency.find(:usd)
    end
    it "includes registered currencies" do
      with_registered_currency(foo_currency) do
        Money::Currency.all.should contain foo_currency
      end
    end
    it "is sorted by priority" do
      Money::Currency.all.first.priority.should eq 1
    end
  end

  describe ".each" do
    it "yields each currency to the block" do
      currencies = [] of Money::Currency
      Money::Currency.each do |currency|
        currencies << currency
      end
      currencies.should eq Money::Currency.all
    end
  end

  it "implements Enumerable" do
    Money::Currency.should be_a Enumerable(Money::Currency)
  end
end
