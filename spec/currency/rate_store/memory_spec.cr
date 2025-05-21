require "../../spec_helper"

describe Money::Currency::RateStore::Memory do
  describe "#[from, to]=" do
    store = Money::Currency::RateStore::Memory.new

    it "stores rate in memory" do
      store["USD", "CAD"] = 0.9
    end
  end

  describe "#[from, to]?" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9

    it "returns stored rate" do
      store["USD", "CAD"]?.should eq 0.9.to_big_d
    end

    it "returns nil if rate is not found" do
      store["CAD", "USD"]?.should be_nil
    end
  end

  describe "#[from, to]" do
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

  describe "#each" do
    store = Money::Currency::RateStore::Memory.new
    store["USD", "CAD"] = 0.9
    store["CAD", "USD"] = 1.1

    it "iterates over rates" do
      rates = [] of String
      store.each do |rate|
        rates << rate.to_s
      end
      rates.should eq [
        "USD -> CAD: 0.9",
        "CAD -> USD: 1.1",
      ]
    end

    it "is an Enumerable" do
      store.should be_a(Enumerable(Money::Currency::Rate))
    end
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
end
