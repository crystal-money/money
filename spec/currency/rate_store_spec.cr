require "../spec_helper"

class Money::Currency
  class RateStore::Dummy < RateStore
    @rates = Hash({Currency, Currency}, Rate).new

    protected def set_rate(rate : Rate) : Nil
      @rates[{rate.base, rate.target}] = rate
    end

    protected def get_rate?(base : Currency, target : Currency) : Rate?
      @rates[{base, target}]?
    end

    protected def each_rate(& : Rate -> _)
      @rates.values.each { |rate| yield rate }
    end

    protected def clear_rates : Nil
      @rates.clear
    end

    protected def clear_rates(base : Currency) : Nil
      @rates.reject! { |(from, _), _| from == base }
    end
  end
end

describe Money::Currency::RateStore do
  usd = Money::Currency.find("USD")
  cad = Money::Currency.find("CAD")
  eur = Money::Currency.find("EUR")

  it "registers and retrieves a rate using #[]= and #[]?" do
    store = Money::Currency::RateStore::Dummy.new
    store[usd, cad] = 1.25
    store[cad, usd] = 0.8

    store[usd, cad]?.should eq 1.25.to_big_d
    store[cad, usd]?.should eq 0.8.to_big_d
    store[eur, usd]?.should be_nil
  end

  it "raises `UnknownRateError` when rate is missing" do
    store = Money::Currency::RateStore::Dummy.new

    expect_raises(Money::UnknownRateError) do
      store[usd, eur]
    end
  end

  it "registers a rate using #<<(Rate)" do
    store = Money::Currency::RateStore::Dummy.new
    store << Money::Currency::Rate.new(usd, cad, 1.33.to_big_d)

    store[usd, cad]?.should eq(1.33.to_big_d)
  end

  it "registers multiple rates using #<<(Enumerable(Rate))" do
    store = Money::Currency::RateStore::Dummy.new
    rates = [
      Money::Currency::Rate.new(usd, cad, 1.1.to_big_d),
      Money::Currency::Rate.new(cad, usd, 0.9.to_big_d),
    ]
    store << rates

    store[usd, cad]?.should eq(1.1.to_big_d)
    store[cad, usd]?.should eq(0.9.to_big_d)
  end

  it "iterates over rates with #each" do
    store = Money::Currency::RateStore::Dummy.new
    store[usd, cad] = 1.2
    store[cad, usd] = 0.8

    arr = [] of Money::Currency::Rate
    store.each do |rate|
      arr << rate
    end
    arr.map(&.to_s).should eq [
      "USD -> CAD: 1.2",
      "CAD -> USD: 0.8",
    ]
  end

  it "clears all rates with #clear" do
    store = Money::Currency::RateStore::Dummy.new
    store[usd, cad] = 1.2
    store[cad, usd] = 0.8

    store.clear

    store.rates.should be_empty
  end

  it "clears rates for a base currency with #clear(base)" do
    store = Money::Currency::RateStore::Dummy.new
    store[usd, cad] = 1.2
    store[usd, eur] = 1.5
    store[cad, usd] = 0.8

    store.clear(usd)

    store[usd, cad]?.should be_nil
    store[usd, eur]?.should be_nil
    store[cad, usd]?.should eq 0.8.to_big_d
  end

  it "returns `nil` for stale rates when ttl is set" do
    store = Money::Currency::RateStore::Dummy.new(ttl: 1.second)
    store << Money::Currency::Rate.new(usd, cad, 1.0.to_big_d, Time.utc - 3.seconds)

    store[usd, cad]?.should be_nil
  end

  it "returns fresh rate when within ttl" do
    store = Money::Currency::RateStore::Dummy.new(ttl: 10.seconds)
    store << Money::Currency::Rate.new(usd, cad, 1.0.to_big_d, Time.utc)

    store[usd, cad]?.should eq 1.0.to_big_d
  end

  it "#rates skips stale rates" do
    store = Money::Currency::RateStore::Dummy.new(ttl: 1.second)
    store << Money::Currency::Rate.new(usd, cad, 1.0.to_big_d, Time.utc)
    store << Money::Currency::Rate.new(cad, usd, 0.8.to_big_d, Time.utc - 3.seconds)

    store.rates.map(&.to_s).should eq [
      "USD -> CAD: 1.0",
    ]
  end

  it "supports #transaction block" do
    store = Money::Currency::RateStore::Dummy.new

    called = false
    store.transaction do
      called = true
    end
    called.should be_true
  end
end
