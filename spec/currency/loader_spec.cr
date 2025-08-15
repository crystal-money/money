require "../spec_helper"

describe Money::Currency::Loader do
  context ".load_defaults" do
    defaults = Money::Currency.load_defaults

    it "returns non-empty currency table hash" do
      defaults.present?.should be_true
    end

    it "sets the hash key to the currency code" do
      defaults.each do |key, currency|
        key.should eq currency.code
      end
    end

    it "returns common currencies within currency table hash" do
      currencies = defaults.values.map(&.code)
      currencies.should contain "USD"
      currencies.should contain "EUR"
      currencies.should contain "BTC"
    end
  end
end
