require "json"
require "yaml"
require "spec"
require "../src/money"

def with_default_currency(currency = nil, &)
  previous_currency = Money.default_currency
  begin
    Money.default_currency = currency if currency
    yield
  ensure
    Money.default_currency = previous_currency
  end
end

def with_registered_currency(*currencies, &)
  currencies.each do |currency|
    Money::Currency.register(currency)
  end
  yield
ensure
  currencies.each do |currency|
    Money::Currency.unregister(currency)
  end
end

def with_default_exchange(exchange = nil, &)
  previous_exchange = Money.default_exchange
  begin
    Money.default_exchange = exchange if exchange
    yield
  ensure
    Money.default_exchange = previous_exchange
  end
end

Spec.around_each do |example|
  Money.default_currency = "USD"
  example.run
ensure
  Money.default_currency = nil
end
