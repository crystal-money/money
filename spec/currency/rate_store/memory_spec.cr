require "../../spec_helper"

describe Money::Currency::RateStore::Memory do
  describe "rates caching" do
    store = Money::Currency::RateStore::Memory.new(ttl: 1.hour)
    store << Money::Currency::Rate.new(
      Money::Currency.find("USD"),
      Money::Currency.find("CAD"),
      0.9.to_big_d,
      Time.utc,
    )
    store << Money::Currency::Rate.new(
      Money::Currency.find("CAD"),
      Money::Currency.find("USD"),
      1.1.to_big_d,
      Time.utc - (1.hour + 1.second),
    )

    describe "#[]?" do
      it "returns nil when rate is stale" do
        store["USD", "CAD"]?.should eq 0.9.to_big_d
        store["CAD", "USD"]?.should be_nil
      end
    end

    describe "#rates" do
      it "skips stale rates" do
        store.rates.map(&.to_s).should eq [
          "USD -> CAD: 0.9",
        ]
      end
    end
  end

  describe "#[base, target]=" do
    store = Money::Currency::RateStore::Memory.new

    it "stores rate in memory" do
      store["USD", "CAD"] = 0.9
    end
  end

  describe "#[base, target]?" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9

    it "returns stored rate" do
      store["USD", "CAD"]?.should eq 0.9.to_big_d
    end

    it "returns nil if rate is not found" do
      store["CAD", "USD"]?.should be_nil
    end
  end

  describe "#[base, target]" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9

    it "returns stored rate" do
      store["USD", "CAD"].should eq 0.9.to_big_d
    end

    it "raises UnknownRateError if rate is not found" do
      expect_raises(Money::UnknownRateError, "No conversion rate known for CAD -> USD") do
        store["CAD", "USD"]
      end
    end
  end

  describe "#<<(rate)" do
    store = Money::Currency::RateStore::Memory.new

    it "stores rate in memory" do
      store << Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("CAD"),
        0.9.to_big_d,
      )
      store["USD", "CAD"].should eq 0.9.to_big_d
    end
  end

  describe "#<<(rates)" do
    store = Money::Currency::RateStore::Memory.new

    it "stores rates in memory" do
      store << [
        Money::Currency::Rate.new(
          Money::Currency.find("USD"),
          Money::Currency.find("CAD"),
          0.9.to_big_d,
        ),
        Money::Currency::Rate.new(
          Money::Currency.find("CAD"),
          Money::Currency.find("USD"),
          1.1.to_big_d,
        ),
      ]
      store["USD", "CAD"].should eq 0.9.to_big_d
      store["CAD", "USD"].should eq 1.1.to_big_d
    end
  end

  describe "#each" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9
    store["CAD", "USD"] = 1.1

    it "iterates over rates" do
      rates = [] of Money::Currency::Rate
      store.each do |rate|
        rates << rate
      end
      rates.map(&.to_s).should eq [
        "USD -> CAD: 0.9",
        "CAD -> USD: 1.1",
      ]
    end
  end

  it "implements Enumerable" do
    store = Money::Currency::RateStore::Memory.new
    store.should be_a Enumerable(Money::Currency::Rate)
  end

  describe "#rates" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9
    store["CAD", "USD"] = 1.1

    it "returns list of rates" do
      store.rates.map(&.to_s).should eq [
        "USD -> CAD: 0.9",
        "CAD -> USD: 1.1",
      ]
    end
  end

  describe "#clear" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9

    it "clears rates" do
      store.size.should eq 1
      store.clear
      store.size.should eq 0
    end
  end

  describe "#clear(base)" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "EUR"] = 1.0
    store["USD", "CAD"] = 0.9
    store["CAD", "USD"] = 1.1

    it "clears rates only for the given base currency" do
      store.size.should eq 3
      store.clear("USD")
      store.size.should eq 1
    end
  end
end
