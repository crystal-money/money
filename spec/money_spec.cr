require "./spec_helper"

private ROUNDING_CONVERSIONS = {
  Number::RoundingMode::TO_ZERO => [
    {10.885, 10.88},
  ],
  Number::RoundingMode::TIES_EVEN => [
    {10.885, 10.88},
  ],
  Number::RoundingMode::TIES_AWAY => [
    {10.885, 10.89},
  ],
}

describe Money do
  describe ".new" do
    context "given the initializing value is an integer" do
      it "stores the integer as the number of cents" do
        Money.new(1).cents.should eq 1
      end
    end

    context "given the initializing value is a float" do
      context "and the value is Infinity" do
        it do
          expect_raises(ArgumentError) { Money.new(-Float32::INFINITY) }
          expect_raises(ArgumentError) { Money.new(-Float64::INFINITY) }
          expect_raises(ArgumentError) { Money.new(Float32::INFINITY) }
          expect_raises(ArgumentError) { Money.new(Float64::INFINITY) }
        end
      end

      context "and the value is NaN" do
        it do
          expect_raises(ArgumentError) { Money.new(Float32::NAN) }
          expect_raises(ArgumentError) { Money.new(Float64::NAN) }
        end
      end

      context "and the value is 1.00" do
        it { Money.new(1.00).should eq Money.new(1.0) }
      end

      context "and the value is 1.01" do
        it { Money.new(1.01).should eq Money.new(1.01) }
      end

      context "and the value is 1.007" do
        it { Money.new(1.007).should eq Money.new(1.01) }
      end

      context "and the value is 1.50" do
        it { Money.new(1.50).should eq Money.new(1.5) }
      end
    end

    context "given the initializing value is a rational" do
      it { Money.new(BigRational.new(1)).should eq Money.new(1.0) }
    end

    context "given there's no amount provided" do
      it "should have zero amount" do
        Money.new.amount.should eq 0
      end
    end

    context "given a currency is not provided" do
      it "should have the default currency" do
        Money.new.currency.should be Money.default_currency
      end
    end

    context "given a currency is provided" do
      context "and the currency is NZD" do
        it "should have NZD currency" do
          Money.new(currency: "NZD").currency.should be Money::Currency.find("NZD")
        end
      end
    end

    context "given a exchange is not provided" do
      it "should return the default exchange" do
        Money.new.exchange.should be Money.default_exchange
      end
    end

    context "given a exchange is provided" do
      exchange = Money::Currency::Exchange::SingleCurrency.new

      it "should return given exchange" do
        Money.new(exchange: exchange).exchange.should be exchange
      end
    end
  end

  describe ".with_rounding_mode" do
    ROUNDING_CONVERSIONS.each do |mode, values|
      values.each do |(value, expected)|
        it "sets `Money.rounding_mode` to `#{mode}` " \
           "within the yielded block and rounds #{value} to #{expected}" do
          prev_rounding_mode = Money.rounding_mode
          begin
            Money.with_rounding_mode(mode) do
              Money.new(value, "USD").round(2).should eq Money.new(expected, "USD")
              Money.new(value, "USD").amount.should eq expected.to_big_d
              Money.new(value, "USD")
                .rounded_to_nearest_cash_value
                .should eq Money.new(expected, "USD")
            end
          ensure
            Money.rounding_mode.should eq prev_rounding_mode
          end
        end
      end
    end
  end

  describe ".disallow_currency_conversions!" do
    it "disallows conversions when doing money arithmetic" do
      with_default_exchange do
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
      Money.from_amount(1.to_big_d, "USD").should eq Money.new(1_00, "USD")
    end

    it "converts given amount to subunits according to currency" do
      Money.from_amount(1, "USD").should eq Money.new(1_00, "USD")
      Money.from_amount(1, "TND").should eq Money.new(1_000, "TND")
      Money.from_amount(1, "JPY").should eq Money.new(1, "JPY")
    end

    it "rounds the given amount to subunits" do
      Money.from_amount(4.444, "USD").amount.should eq 4.44.to_big_d
      Money.from_amount(5.555, "USD").amount.should eq 5.56.to_big_d
      Money.from_amount(444.4, "JPY").amount.should eq 444.to_big_d
      Money.from_amount(555.5, "JPY").amount.should eq 556.to_big_d
    end

    it "does not round the given amount when .infinite_precision? is set" do
      Money.with_infinite_precision do
        Money.from_amount(4.444, "USD").amount.should eq 4.444.to_big_d
        Money.from_amount(5.555, "USD").amount.should eq 5.555.to_big_d
        Money.from_amount(444.4, "JPY").amount.should eq 444.4.to_big_d
        Money.from_amount(555.5, "JPY").amount.should eq 555.5.to_big_d
      end
    end

    it "uses the default currency when no currency is provided" do
      Money.from_amount(1).currency.should eq Money.default_currency
    end

    it "accepts an optional currency" do
      Money::Currency.find("JPY").tap do |jpy|
        Money.from_amount(1, jpy).currency.should be jpy
        Money.from_amount(1, "JPY").currency.should be jpy
      end
    end
  end

  describe "#==" do
    it "returns true if both amounts are zero, even if currency differs" do
      Money.new(0, "USD").should eq Money.new(0, "USD")
      Money.new(0, "USD").should eq Money.new(0, "EUR")
      Money.new(0, "USD").should eq Money.new(0, "AUD")
      Money.new(0, "USD").should eq Money.new(0, "JPY")
    end
  end

  describe "#<=>" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["EUR", "USD"] = 1.5
    exchange.rate_store["USD", "EUR"] = 2

    it "compares the two object amounts (same currency)" do
      (Money.new(1_00, "USD") <=> Money.new(1_00, "USD")).should eq 0
      (Money.new(1_00, "USD") <=> Money.new(99, "USD")).should be > 0
      (Money.new(1_00, "USD") <=> Money.new(2_00, "USD")).should be < 0
    end

    it "converts other object amount to current currency, then compares the two object amounts (different currency)" do
      with_default_exchange(exchange) do
        (Money.new(150_00, "USD") <=> Money.new(100_00, "EUR")).should eq 0
        (Money.new(200_00, "USD") <=> Money.new(200_00, "EUR")).should be < 0
        (Money.new(800_00, "USD") <=> Money.new(400_00, "EUR")).should be > 0
      end
    end

    it "raises UnknownRateError if currency conversion fails, and therefore cannot be compared" do
      expect_raises(Money::UnknownRateError) do
        Money.new(100_00, "USD") <=> Money.new(200_00, "EUR")
      end
    end

    context "when conversions disallowed" do
      context "when currencies differ" do
        context "when both values are 1_00" do
          it "raises currency error" do
            with_default_exchange do
              Money.disallow_currency_conversion!
              expect_raises(Money::DifferentCurrencyError) do
                Money.us_dollar(1_00) <=> Money.euro(1_00)
              end
            end
          end
        end

        context "when both values are 0" do
          it "considers them equal" do
            with_default_exchange do
              Money.disallow_currency_conversion!
              (Money.us_dollar(0) <=> Money.euro(0)).should eq 0
            end
          end
        end
      end
    end
  end

  describe "#eql?" do
    it "compares the two object amounts and currencies without performing currency conversion" do
      Money.new(1_00, "USD").eql?(Money.new(1_00, "USD")).should be_true
      Money.new(1_00, "USD").eql?(Money.new(1_00, "EUR")).should be_false
      Money.new(1_00, "USD").eql?(Money.new(1_23, "USD")).should be_false

      Money.zero("USD").eql?(Money.zero("USD")).should be_true
      Money.zero("USD").eql?(Money.zero("EUR")).should be_false
    end
  end

  describe "Steppable" do
    it "allows stepping ranges" do
      range = Money.new(1_00, "USD")..Money.new(3_00, "USD")
      range.step(by: Money.new(1_00, "USD")).to_a.should eq [
        Money.new(1_00, "USD"),
        Money.new(2_00, "USD"),
        Money.new(3_00, "USD"),
      ]
    end
  end

  describe "#fractional" do
    it "returns the amount in fractional unit" do
      money = Money.new(1_00)
      money.fractional.should eq 1_00
      money.fractional.should be_a BigDecimal
    end

    it "rounds the amount to smallest unit of coinage" do
      money = Money.new(fractional: 1_00.555.to_big_d)
      money.fractional.should eq 1_01
    end

    it "does not round the given amount when .infinite_precision? is set" do
      Money.with_infinite_precision do
        money = Money.new(fractional: 1_00.555.to_big_d)
        money.fractional.should eq 1_00.555.to_big_d
      end
    end

    context "loading a serialized Money via JSON" do
      money = Money.from_json(%q({
        "amount": "33.00",
        "currency": "EUR"
      }))

      it "loads fractional" do
        money.fractional.should eq 33_00
      end

      it "loads currency by string" do
        money.currency.should eq Money::Currency.find("EUR")
      end
    end
  end

  describe "#with_currency" do
    it "returns self if currency is the same" do
      money = Money.new(10_00, "USD")
      money.with_currency("USD").should eq money
    end

    it "returns a new instance in a given currency" do
      money = Money.new(10_00, "USD")
      new_money = money.with_currency("EUR")

      new_money.should eq Money.new(10_00, "EUR")
      new_money.amount.should eq money.amount
      new_money.exchange.should eq money.exchange
    end
  end

  describe "#nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      sets = {
        {2350, "AED", 2350},
        {-2350, "AED", -2350},
        {2213, "AED", 2225},
        {-2213, "AED", -2225},
        {2212, "AED", 2200},
        {-2212, "AED", -2200},
        {178, "CHF", 180},
        {-178, "CHF", -180},
        {177, "CHF", 175},
        {-177, "CHF", -175},
        {175, "CHF", 175},
        {-175, "CHF", -175},
        {299, "USD", 299},
        {-299, "USD", -299},
        {300, "USD", 300},
        {-300, "USD", -300},
        {301, "USD", 301},
        {-301, "USD", -301},
      }
      sets.each do |(fractional, currency, expected)|
        Money.new(fractional, currency).nearest_cash_value.should eq expected
      end
    end

    it "raises an exception if smallest denomination is not defined" do
      money = Money.new(100, "XAG")
      expect_raises(Money::UndefinedSmallestDenominationError) do
        money.nearest_cash_value
      end
    end

    it "returns a BigDecimal" do
      Money.new(100, "EUR").nearest_cash_value.should be_a BigDecimal
    end
  end

  describe "#rounded_to_nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      Money.new(-2213, "AED").rounded_to_nearest_cash_value.cents.should eq -2225
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
      Money.new(100_37).amount.should eq 100.37.to_big_d
    end

    it "produces a BigDecimal" do
      Money.new.amount.should be_a BigDecimal
    end
  end

  describe "#round" do
    it "returns rounded value with given precision" do
      Money.new(10.12345, "USD").round.amount.should eq 10.to_big_d
      Money.new(10.12345, "USD").round(1).amount.should eq 10.1.to_big_d
      Money.new(10.12345, "USD").round(2).amount.should eq 10.12.to_big_d
      Money.new(10.12345, "USD").round(3).amount.should eq 10.12.to_big_d
      Money.new(10.12345, "USD").round(4).amount.should eq 10.12.to_big_d
    end

    context "with Money.infinite_precision = true" do
      it "returns rounded value with given precision" do
        Money.with_infinite_precision do
          Money.new(10.12345, "USD").round.amount.should eq 10.to_big_d
          Money.new(10.12345, "USD").round(1).amount.should eq 10.1.to_big_d
          Money.new(10.12345, "USD").round(2).amount.should eq 10.12.to_big_d
          Money.new(10.12345, "USD").round(3).amount.should eq 10.123.to_big_d
          Money.new(10.12345, "USD").round(4).amount.should eq 10.1234.to_big_d
        end
      end

      it "returns rounded value with given precision and rounding mode" do
        Money.with_infinite_precision do
          Money.new(10.12345, "USD").round.amount
            .should eq 10.to_big_d
          Money.new(10.12345, "USD").round(1, mode: :ties_even).amount
            .should eq 10.1.to_big_d
          Money.new(10.12345, "USD").round(2, mode: :ties_even).amount
            .should eq 10.12.to_big_d
          Money.new(10.12345, "USD").round(3, mode: :ties_even).amount
            .should eq 10.123.to_big_d
          Money.new(10.12345, "USD").round(4, mode: :ties_even).amount
            .should eq 10.1234.to_big_d
          Money.new(10.12345, "USD").round(4, mode: :ties_away).amount
            .should eq 10.1235.to_big_d
        end
      end
    end
  end

  describe "#currency" do
    it "returns default Currency object" do
      Money.new.currency.should be Money.default_currency
    end

    it "returns Currency object passed in #initialize" do
      Money.new(currency: "EUR").currency.should be Money::Currency.find("EUR")
    end
  end

  describe "#exchange" do
    it "returns default Currency::Exchange object" do
      Money.new.exchange.should be Money.default_exchange
    end

    it "returns Currency::Exchange object passed in #initialize" do
      Money::Currency::Exchange::SingleCurrency.new.tap do |exchange|
        Money.new(exchange: exchange).exchange.should be exchange
      end
    end

    it "takes Currency::Exchange object" do
      Money::Currency::Exchange::SingleCurrency.new.tap do |exchange|
        Money.new.tap do |money|
          money.exchange = exchange
          money.exchange.should be exchange
        end
      end
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

    pending "can be used to return the intersection of Money object arrays" do
      moneys = [Money.new(1_00, "EUR"), Money.new(1_00, "USD")]

      intersection = moneys & [Money.new(1_00, "EUR")]
      intersection.should eq [Money.new(1_00, "EUR")]
    end
  end

  describe ".default_currency" do
    it "accepts a string" do
      with_default_currency("PLN") do
        Money.default_currency.should be Money::Currency.find("PLN")
      end
    end

    it "accepts a symbol" do
      with_default_currency(:pln) do
        Money.default_currency.should be Money::Currency.find("PLN")
      end
    end
  end

  describe ".default_exchange" do
    it "returns the Currency::Exchange object" do
      Money.default_exchange.should be_a Money::Currency::Exchange
    end

    it "sets the value to the given Currency::Exchange object" do
      exchange = Money::Currency::Exchange::SingleCurrency.new
      with_default_exchange(exchange) do
        Money.default_exchange.should be exchange
      end
    end
  end

  describe ".spawn_with_same_context" do
    it "spawns a fiber with the same context (dup-ed)" do
      with_default_currency("PLN") do
        channel = Channel(Money::Context).new

        Money.spawn_with_same_context do
          channel.send Money.context
        end
        channel.receive.should_not be Money.context
      end
    end

    it "spawns a fiber with the same context" do
      with_default_currency("PLN") do
        channel = Channel(String).new

        Money.spawn_with_same_context do
          channel.send Money.default_currency.code
        end
        channel.receive.should eq "PLN"
      end
    end

    it "doesn't leak the context" do
      with_default_currency("PLN") do
        channel = Channel(Nil).new

        Money.spawn_with_same_context do
          Money.default_currency = "EUR"
          channel.send nil
        end
        channel.receive
        Money.default_currency.code.should eq "PLN"
      end
    end
  end
end
