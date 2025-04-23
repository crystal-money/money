require "../../spec_helper"

describe Money::Currency::RateStore::Memory do
  describe "#[]= and #[]" do
    store = Money::Currency::RateStore::Memory.new

    it "stores rate in memory" do
      store["USD", "CAD"] = 0.9
      store["USD", "CAD"].should eq 0.9.to_big_d
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
      rates.should eq [
        Money::Currency::Rate.new(
          Money::Currency.find("USD"),
          Money::Currency.find("CAD"),
          90_i64
        ),
        Money::Currency::Rate.new(
          Money::Currency.find("CAD"),
          Money::Currency.find("USD"),
          110_i64
        ),
      ]
    end

    it "is an Enumerable" do
      store.should be_a(Enumerable(Money::Currency::Rate))
    end
  end
end
