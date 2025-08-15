require "../../spec_helper"

private CURRENCY_RATES = [
  Money::Currency::Rate.new(
    Money::Currency.find("USD"),
    Money::Currency.find("CAD"),
    0.9.to_big_d,
    Time.parse_utc("2025-05-22", "%F"),
  ),
  Money::Currency::Rate.new(
    Money::Currency.find("CAD"),
    Money::Currency.find("USD"),
    1.1.to_big_d,
    Time.parse_utc("2025-05-22", "%F"),
  ),
]

private def with_currency_file_store(&)
  tempfile = File.tempfile(suffix: ".json") do |file|
    CURRENCY_RATES.to_json(file)
  end
  begin
    store = Money::Currency::RateStore::File.new(tempfile.path)
    yield store, tempfile
  ensure
    tempfile.delete
  end
end

describe Money::Currency::RateStore::File do
  describe "#initialize" do
    it "loads rates from a JSON file" do
      with_currency_file_store do |store|
        store.rates.map(&.to_s).should eq [
          "USD -> CAD: 0.9",
          "CAD -> USD: 1.1",
        ]
      end
    end
  end

  describe "#load" do
    it "loads rates from a JSON file" do
      with_currency_file_store do |store, file|
        rates = [
          Money::Currency::Rate.new(
            Money::Currency.find("USD"),
            Money::Currency.find("EUR"),
            1.to_big_d,
          ),
        ]
        File.write(file.path, rates.to_json)

        store.load
        store.rates.map(&.to_s).should eq [
          "USD -> EUR: 1.0",
        ]
      end
    end

    it "does nothing if the file does not exist" do
      store = Money::Currency::RateStore::File.new("does/not/exist.json")
      store.load
      store.empty?.should be_true
    end
  end

  describe "#[]=" do
    it "persists rates to a JSON file" do
      with_currency_file_store do |store, file|
        store["USD", "EUR"] = 1.1
        store["USD", "CAD"] = 2.2
        store["CAD", "USD"] = 3.3

        rates = Array(Money::Currency::Rate).from_json(File.read(file.path))
        rates.map(&.to_s).should eq [
          "USD -> CAD: 2.2",
          "CAD -> USD: 3.3",
          "USD -> EUR: 1.1",
        ]
        rates.each do |rate|
          rate.updated_at.should be_close(Time.utc, 3.seconds)
        end
      end
    end

    describe "#<<" do
      it "persists rates to a JSON file" do
        with_currency_file_store do |store, file|
          store << [
            Money::Currency::Rate.new(
              Money::Currency.find("USD"),
              Money::Currency.find("EUR"),
              1.1.to_big_d,
              Time.parse_utc("2025-05-22", "%F"),
            ),
            Money::Currency::Rate.new(
              Money::Currency.find("USD"),
              Money::Currency.find("CAD"),
              2.2.to_big_d,
              Time.parse_utc("2025-05-22", "%F"),
            ),
            Money::Currency::Rate.new(
              Money::Currency.find("CAD"),
              Money::Currency.find("USD"),
              3.3.to_big_d,
              Time.parse_utc("2025-05-22", "%F"),
            ),
          ]

          json = File.read(file.path)
          json.should eq <<-JSON
            [
              {
                "base": "USD",
                "target": "CAD",
                "value": 2.2,
                "updated_at": "2025-05-22T00:00:00Z"
              },
              {
                "base": "CAD",
                "target": "USD",
                "value": 3.3,
                "updated_at": "2025-05-22T00:00:00Z"
              },
              {
                "base": "USD",
                "target": "EUR",
                "value": 1.1,
                "updated_at": "2025-05-22T00:00:00Z"
              }
            ]
            JSON
        end
      end
    end

    describe "#clear(base)" do
      it "persists rates to a JSON file" do
        with_currency_file_store do |store, file|
          store.clear("USD")

          json = File.read(file.path)
          json.should eq <<-JSON
            [
              {
                "base": "CAD",
                "target": "USD",
                "value": 1.1,
                "updated_at": "2025-05-22T00:00:00Z"
              }
            ]
            JSON
        end
      end
    end

    describe "#clear" do
      it "persists rates to a JSON file" do
        with_currency_file_store do |store, file|
          store.clear

          json = File.read(file.path)
          json.should eq "[]"
        end
      end
    end
  end
end
