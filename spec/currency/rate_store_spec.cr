require "../spec_helper"

class Money::Currency
  class RateStore::Dummy < RateStore
    getter? foo_option : Bool

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    @rates = {} of String => Rate

    def initialize(*, ttl : Time::Span? = nil, @foo_option = false)
      super(ttl: ttl)
    end

    protected def set_rate(rate : Rate) : Nil
      @rates["%s_%s" % {rate.base.code, rate.target.code}] = rate
    end

    protected def get_rate?(base : Currency, target : Currency) : Rate?
      @rates["%s_%s" % {base.code, target.code}]?
    end

    protected def each_rate(& : Rate ->)
      @rates.values.each { |rate| yield rate }
    end

    protected def clear_rates : Nil
      @rates.clear
    end

    protected def clear_rates(base : Currency) : Nil
      @rates.reject! { |_, rate| rate.base == base }
    end
  end
end

describe Money::Currency::RateStore do
  usd = Money::Currency.find("USD")
  cad = Money::Currency.find("CAD")
  eur = Money::Currency.find("EUR")

  context "JSON serialization" do
    dummy_store_json = <<-JSON
      {
        "ttl": "1 hour, 15 minutes",
        "foo_option": true
      }
      JSON

    describe ".from_json" do
      context "(generic)" do
        it "returns unserialized object" do
          store = Money::Currency::RateStore.from_json <<-JSON
            {
              "name": "Dummy",
              "options": {
                "ttl": "1 hour, 15 minutes",
                "foo_option": true
              }
            }
            JSON

          store = store.should be_a Money::Currency::RateStore::Dummy
          store.foo_option?.should be_true
          store.ttl.should eq 1.hour + 15.minutes
        end
      end

      it "returns unserialized object" do
        store =
          Money::Currency::RateStore::Dummy.from_json(dummy_store_json)

        store.foo_option?.should be_true
        store.ttl.should eq 1.hour + 15.minutes
      end
    end

    describe "#to_json" do
      it "works as intended" do
        Money::Currency::RateStore::Dummy
          .from_json(dummy_store_json).to_pretty_json
          .should eq dummy_store_json
      end
    end
  end

  context "YAML serialization" do
    dummy_store_yaml = <<-YAML
      ---
      ttl: 1 hour, 15 minutes
      foo_option: true\n
      YAML

    describe ".from_yaml" do
      context "(generic)" do
        it "returns unserialized object" do
          store = Money::Currency::RateStore.from_yaml <<-YAML
            name: Dummy
            options:
              ttl: 1 hour, 15 minutes
              foo_option: true
            YAML

          store = store.should be_a Money::Currency::RateStore::Dummy
          store.foo_option?.should be_true
          store.ttl.should eq 1.hour + 15.minutes
        end
      end

      it "returns unserialized object" do
        store =
          Money::Currency::RateStore::Dummy.from_yaml(dummy_store_yaml)

        store.foo_option?.should be_true
        store.ttl.should eq 1.hour + 15.minutes
      end
    end

    describe "#to_yaml" do
      it "works as intended" do
        Money::Currency::RateStore::Dummy
          .from_yaml(dummy_store_yaml).to_yaml
          .should eq dummy_store_yaml
      end
    end
  end

  context ".key" do
    it "returns store key" do
      Money::Currency::RateStore::Dummy.key.should eq "dummy"
    end
  end

  context ".registry" do
    it "registers subclasses in stores" do
      Money::Currency::RateStore.registry.has_key?("dummy").should be_true
      Money::Currency::RateStore.registry["dummy"]
        .should eq Money::Currency::RateStore::Dummy
    end
  end

  context ".find?" do
    it "returns store by CamelCase name (string)" do
      Money::Currency::RateStore.find?("Dummy")
        .should eq Money::Currency::RateStore::Dummy
    end

    it "returns store by snake_case name (string)" do
      Money::Currency::RateStore.find?("dummy")
        .should eq Money::Currency::RateStore::Dummy

      Money::Currency::RateStore.find?("DUMMY")
        .should eq Money::Currency::RateStore::Dummy
    end

    it "returns store by snake_case name (symbol)" do
      Money::Currency::RateStore.find?(:dummy)
        .should eq Money::Currency::RateStore::Dummy
    end

    it "returns nil for unknown store" do
      Money::Currency::RateStore.find?("foo").should be_nil
    end
  end

  context ".find" do
    it "returns store by name (string)" do
      Money::Currency::RateStore.find("dummy")
        .should eq Money::Currency::RateStore::Dummy
    end

    it "returns store by name (symbol)" do
      Money::Currency::RateStore.find(:dummy)
        .should eq Money::Currency::RateStore::Dummy
    end

    it "raises exception for unknown store" do
      expect_raises(Money::Currency::RateStore::NotFoundError, "Unknown rate store: foo") do
        Money::Currency::RateStore.find("foo")
      end
    end
  end

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

    store[usd, cad]?.should eq 1.33.to_big_d
  end

  it "registers multiple rates using #<<(Enumerable(Rate))" do
    store = Money::Currency::RateStore::Dummy.new
    rates = [
      Money::Currency::Rate.new(usd, cad, 1.1.to_big_d),
      Money::Currency::Rate.new(cad, usd, 0.9.to_big_d),
    ]
    store << rates

    store[usd, cad]?.should eq 1.1.to_big_d
    store[cad, usd]?.should eq 0.9.to_big_d
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
