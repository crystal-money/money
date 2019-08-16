require "spec"
require "../src/money"

def with_infinite_precision(enabled = true)
  previous_value = Money.infinite_precision?
  begin
    Money.infinite_precision = enabled
    yield
  ensure
    Money.infinite_precision = previous_value
  end
end

def with_default_currency(currency = nil)
  previous_currency = Money.default_currency
  begin
    Money.default_currency = currency if currency
    yield
  ensure
    Money.default_currency = previous_currency
  end
end

def with_registered_currency(*currencies)
  currencies.each do |currency|
    Money::Currency.register(currency)
  end
  yield
ensure
  currencies.each do |currency|
    Money::Currency.unregister(currency)
  end
end

def with_default_bank(bank = nil)
  previous_bank = Money.default_bank
  begin
    Money.default_bank = bank if bank
    yield
  ensure
    Money.default_bank = previous_bank
  end
end
