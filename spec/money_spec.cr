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

struct Money
  def copy_with(**options) : Money
    previous_def
  end
end

describe Money do
  describe "implements Steppable" do
    it "allows stepping ranges" do
      range = Money.new(1_00, "USD")..Money.new(3_00, "USD")
      range.step(by: Money.new(1_00, "USD")).to_a.should eq [
        Money.new(1_00, "USD"),
        Money.new(2_00, "USD"),
        Money.new(3_00, "USD"),
      ]
    end
  end

  describe ".configure" do
    it "yields the current `Money.context`" do
      Money.configure do |context|
        context.should be_a Money::Context
        context.should be Money.context
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
                .round_to_nearest_cash_value
                .should eq Money.new(expected, "USD")
            end
          ensure
            Money.rounding_mode.should eq prev_rounding_mode
          end
        end
      end
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

  describe ".without_currency_conversion" do
    it "disallows conversions within the yielded block" do
      with_default_exchange do
        prev_exchange = Money.default_exchange

        Money.without_currency_conversion do
          expect_raises(Money::DifferentCurrencyError) do
            Money.new(100, "USD") + Money.new(100, "EUR")
          end
        end
        Money.default_exchange.should eq prev_exchange
      end
    end
  end

  describe ".disallow_currency_conversion!" do
    it "disallows conversions when doing money arithmetic" do
      with_default_exchange do
        Money.disallow_currency_conversion!

        expect_raises(Money::DifferentCurrencyError) do
          Money.new(100, "USD") + Money.new(100, "EUR")
        end
      end
    end
  end

  describe "#hash" do
    it "returns the same value for equal objects" do
      Money.new(1_00, "EUR").hash.should eq Money.new(1_00, "EUR").hash
      Money.new(2_00, "USD").hash.should eq Money.new(2_00, "USD").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(2_00, "EUR").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(1_00, "USD").hash
      Money.new(1_00, "EUR").hash.should_not eq Money.new(2_00, "USD").hash
    end
  end

  describe "#==" do
    it "returns true even if exchange differs" do
      Money.new(1_00, "USD", Money::Currency::Exchange.new)
        .should eq Money.new(1_00, "USD", Money::Currency::Exchange.new)
    end

    it "returns true if amounts and currencies are equal" do
      Money.new(1_00, "USD").should eq Money.new(1_00, "USD")
      Money.new(1_00, "USD").should_not eq Money.new(5_00, "USD")
      Money.new(1_00, "USD").should_not eq Money.new(1_00, "EUR")
    end
  end

  describe "#=~" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["EUR", "USD"] = 2

    it "returns true even if exchange differs" do
      (Money.new(1_00, "USD", Money::Currency::Exchange.new) =~
        Money.new(1_00, "USD", Money::Currency::Exchange.new)).should be_true
    end

    it "returns true if both amounts are zero, even if currency differs" do
      (Money.zero("USD") =~ Money.zero("USD")).should be_true
      (Money.zero("USD") =~ Money.zero("EUR")).should be_true
      (Money.zero("EUR") =~ Money.zero("JPY")).should be_true
    end

    it "returns true if converted amount is equal" do
      with_default_exchange(exchange) do
        (Money.new(2_00, "USD") =~ Money.new(1_00, "EUR")).should be_true
        (Money.new(6_00, "USD") =~ Money.new(1_00, "EUR")).should be_false
      end
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

    it "compares the two object amounts (zero amounts)" do
      (Money.zero("USD") <=> Money.zero("EUR")).should eq 0
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

  describe "#succ" do
    it "returns the next value" do
      Money.new(1_00, "USD").succ.should eq Money.new(1_01, "USD")
      Money.new(1, "JPY").succ.should eq Money.new(2, "JPY")
    end

    it "works with ranges" do
      range = Money.new(1_00, "USD")..Money.new(1_03, "USD")
      range.to_a.should eq [
        Money.new(1_00, "USD"),
        Money.new(1_01, "USD"),
        Money.new(1_02, "USD"),
        Money.new(1_03, "USD"),
      ]
      range = Money.new(1, "JPY")..Money.new(3, "JPY")
      range.to_a.should eq [
        Money.new(1, "JPY"),
        Money.new(2, "JPY"),
        Money.new(3, "JPY"),
      ]
    end
  end

  describe "#copy_with" do
    it "copies the currency" do
      Money.new(1_00, "EUR").copy_with(fractional: 3_00)
        .should eq Money.new(3_00, "EUR")
    end

    it "copies the exchange" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)

      money = Money.new(1_00, "EUR", exchange)
      money.exchange.should be exchange

      money.copy_with(fractional: 3_00).exchange
        .should be exchange
    end

    it "does not materialize the `exchange` property" do
      money = Money.new(1_00, "EUR")
      money.@exchange.should be_nil

      money.copy_with(fractional: 3_00).@exchange
        .should be_nil
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
end
