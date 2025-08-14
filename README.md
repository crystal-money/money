# money [![CI](https://github.com/crystal-money/money/actions/workflows/ci.yml/badge.svg)](https://github.com/crystal-money/money/actions/workflows/ci.yml) [![Releases](https://img.shields.io/github/release/crystal-money/money.svg)](https://github.com/crystal-money/money/releases) [![License](https://img.shields.io/github/license/crystal-money/money.svg)](https://github.com/crystal-money/money/blob/master/LICENSE)

Hey there! 👋 Welcome to **money**, a Crystal shard for handling money and currency conversion, inspired by [RubyMoney](https://github.com/RubyMoney/money).

## Why Use This Library?

Here’s what you get out of the box:

- A `Money` class to represent amounts and their currencies.
- A flexible `Money::Currency` class for all your currency info needs.
- A growing list of 200+ supported currencies (metals, fiat, cryptocurrencies).
- `BigDecimal`-based values — i.e. no more floating point rounding headaches!
- Easy APIs for currency exchange.
- Multiple exchange rate providers (use built-in or roll your own).
- Comprehensive support for formatting and parsing money values.
- Mathematical operations on `Money` objects:
  - Arithmetic: addition, subtraction, multiplication, division, etc.
  - Rounding and truncation helpers.
  - Allocation and splitting.
- Money ranges.
- JSON/YAML serialization and deserialization support.
- Extensible architecture of exchange rate providers and stores.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  money:
    github: crystal-money/money
```

Then run:

```shell
shards install
```

And require it in your project:

```crystal
require "money"
```

> [!TIP]
> If you wish to use YAML serialization, remember to `require "yaml"`
> **before** requiring `money`.

## Quick Examples

### Creating Money

> [!NOTE]
> `Money.new` first positional argument will treat the given value as the `fractional`
> if it's an integer, and the `amount` otherwise.

```crystal
money = Money.new(10_00, "USD")
money.amount        # => 10.0
money.fractional    # => 1000.0
money.currency.code # => "USD"
```

#### From fractional amount

```crystal
Money.from_fractional(10_00.0, "USD")
Money.from_fractional(10_00, "USD")

Money.new(fractional: 10_00.0, currency: "USD")
Money.new(fractional: 10_00, currency: "USD")
Money.new(10_00, "USD")
```

#### From whole amount

```crystal
Money.from_amount(10.0, "USD")
Money.from_amount(10, "USD")

Money.new(amount: 10.0, currency: "USD")
Money.new(amount: 10, currency: "USD")
Money.new(10.0, "USD")
```

### Comparing Money

> [!NOTE]
> Performs currency conversion if necessary.

```crystal
Money.default_exchange.rate_store["EUR", "USD"] = 1

Money.new(11_00, "USD") < Money.new(33_00, "USD") # => true
Money.new(11_00, "USD") > Money.new(33_00, "EUR") # => false
```

#### Strict Comparison (`==` / `!=`)

> [!NOTE]
> Does **not** perform currency conversion.

```crystal
Money.new(11_00, "USD") == Money.new(11_00, "USD") # => true
Money.new(11_00, "USD") == Money.new(11_00, "EUR") # => false
```

#### Loose Comparison (`=~` / `!~`)

> [!NOTE]
> Performs currency conversion if necessary.

```crystal
Money.new(11_00, "USD") =~ Money.new(11_00, "USD") # => true
Money.new(11_00, "USD") =~ Money.new(11_00, "EUR") # => true
```

> [!CAUTION]
> Two `Money` objects with `0` amount are considered equal, regardless of their currency.

```crystal
Money.zero("USD") =~ Money.zero("EUR") # => true
```

### Arithmetic

> [!NOTE]
> Performs currency conversion if necessary.

```crystal
Money.new(10_00, "USD") + Money.new(5_00, "USD") # => Money(@amount=15.0, @currency="USD")
Money.new(22_00, "USD") - Money.new(2_00, "USD") # => Money(@amount=20.0, @currency="USD")
Money.new(22_00, "USD") / 2                      # => Money(@amount=11.0, @currency="USD")
Money.new(11_00, "USD") * 5                      # => Money(@amount=55.0, @currency="USD")
```

### Unit/Subunit Conversions

```crystal
Money.from_amount(5, "USD").fractional # => 500.0
Money.from_amount(5, "JPY").fractional # => 5.0
Money.from_amount(5, "TND").fractional # => 5000.0
```

### Currency Conversion

In order to perform currency exchange, you need to set up a `Money::Currency::Exchange::RateProvider` or add the rates manually:

```crystal
Money.default_exchange.rate_store["USD", "EUR"] = 1.24515
Money.default_exchange.rate_store["EUR", "USD"] = 0.80311
```

Then you can perform the exchange:

```crystal
Money.new(1_00, "USD").exchange_to("EUR") # => Money(@amount=1.24, @currency="EUR")
Money.new(1_00, "EUR").exchange_to("USD") # => Money(@amount=0.8, @currency="USD")
```

Comparison and arithmetic operations work as expected:

```crystal
Money.new(10_00, "EUR") =~ Money.new(10_00, "USD") # => false
Money.new(10_00, "EUR") + Money.new(10_00, "USD")  # => Money(@amount=22.45, @currency="EUR")
```

### Formatting

```crystal
Money.new(1_00, "USD").format # => "$1.00"
Money.new(1_00, "EUR").format # => "€1.00"
Money.new(1_00, "PLN").format # => "1,00 zł"
```

### Money Ranges

```crystal
range = Money.new(1_00, "USD")..Money.new(3_00, "USD")
range.to_a(&.format)
# => ["$1.00", "$1.01", "$1.02", ..., "$2.99", "$3.00"]
```

#### Steppable Ranges

```crystal
range = Money.new(1_00, "USD")..Money.new(3_00, "USD")
range
  .step(by: Money.new(1_00, "USD"))
  .to_a(&.format)
# => ["$1.00", "$2.00", "$3.00"]
```

#### Clamping

```crystal
Money.new(10_00, "USD").clamp(
  min: Money.new(1_00, "USD"),
  max: Money.new(9_00, "USD"),
) # => Money(@amount=9.0, @currency="USD")

# or

Money.new(10_00, "USD").clamp(
  Money.new(1_00, "USD")..Money.new(9_00, "USD"),
) # => Money(@amount=9.0, @currency="USD")
```

## Infinite Precision

By default, `Money` objects are rounded to the nearest cent and the extra precision
is **not** preserved:

```crystal
Money.new(2.34567, "USD").format # => "$2.35"
```

If you want to keep all the digits, you can enable infinite precision globally:

```crystal
Money.infinite_precision = true
Money.new(2.34567, "USD").format # => "$2.34567"
```

Or use the block-scoped `Money.with_infinite_precision`:

```crystal
Money.with_infinite_precision do
  Money.new(2.34567, "USD").format # => "$2.34567"
end
```

## Currencies

A `Money::Currency` instance holds all the info about the currency:

```crystal
currency = Money::Currency.find("USD")
currency.code   # => "USD"
currency.name   # => "United States Dollar"
currency.symbol # => "$"
currency.fiat?  # => true
```

Most APIs let you use a `String`, `Symbol`, or a `Money::Currency`:

```crystal
# All of the following are equivalent:

Money.default_currency = Money::Currency.find("CAD")
Money.default_currency = "CAD"
Money.default_currency = :cad
```

### Currency Lookup

`Money::Currency.find` and `Money::Currency.[]` methods let you find a currency by its code:

```crystal
Money::Currency.find("USD") # => #<Money::Currency @code="USD">
Money::Currency[:usd]       # => #<Money::Currency @code="USD">
Money::Currency[:foo]       # raises Money::UnknownCurrencyError
```

There are also `Money::Currency.find?` and `Money::Currency.[]?` non-raising methods:

```crystal
Money::Currency.find?("USD") # => #<Money::Currency @code="USD">
Money::Currency[:usd]?       # => #<Money::Currency @code="USD">
Money::Currency[:foo]?       # => nil
```

### Currency Enumeration

> [!TIP]
> `Money::Currency` class implements `Enumerable` module, so you can use all of its
> methods like `each`, `map`, `find`, `select`, etc.

For example, to find a currency by ISO 4217 numeric code:

```crystal
Money::Currency.find(&.iso_numeric.==(978)) # => #<Money::Currency @code="EUR">
```

Or to select all the ISO currencies:

```crystal
Money::Currency.select(&.iso?)
# => [#<Money::Currency @code="USD">, #<Money::Currency @code="EUR">, ...]
```

In addition, there are `Money::Currency.metal`, `Money::Currency.fiat` and
`Money::Currency.crypto` methods to get all the currencies of a particular `type`:

```crystal
Money::Currency.metal
# => [#<Money::Currency @code="XAG">, #<Money::Currency @code="XAU">, ...]
Money::Currency.fiat
# => [#<Money::Currency @code="USD">, #<Money::Currency @code="EUR">, ...]
Money::Currency.crypto
# => [#<Money::Currency @code="BTC">, #<Money::Currency @code="ETH">, ...]

# or
Money::Currency.reject(&.metal?)
# => [#<Money::Currency @code="USD">, #<Money::Currency @code="EUR">, ...]
```

To return an array of registered currencies (ordered by their priority),
call `Money::Currency.all` or `.to_a`:

```crystal
Money::Currency.all # => [#<Money::Currency @code="USD">, #<Money::Currency @code="EUR">, ...]
```

### Registering a New Currency

```crystal
currency = Money::Currency.new(
  type:                :fiat,
  priority:            1,
  code:                "USD",
  iso_numeric:         840,
  name:                "United States Dollar",
  symbol:              "$",
  symbol_first:        true,
  subunit:             "Cent",
  subunit_to_unit:     100,
  decimal_mark:        ".",
  thousands_separator: ","
)

Money::Currency.register(currency)
```

#### Currency Attributes

- `:type` — a `Money::Currency::Type` - either `Metal`, `Fiat` or `Crypto`
- `:priority` — a numerical value you can use to sort/group the currency list
- `:code` — the international 3-letter code as defined by the ISO 4217 standard
- `:iso_numeric` — the international 3-digit code as defined by the ISO 4217 standard
- `:name` — the currency name
- `:symbol` — the currency symbol (UTF-8 encoded)
- `:symbol_first` — whether a money symbol should go before the amount
- `:subunit` — the name of the fractional monetary unit
- `:subunit_to_unit` — the proportion between the unit and the subunit
- `:decimal_mark` — character between the whole and fraction amounts
- `:thousands_separator` — character between each thousands place
- `:format` — a format string passed to `Money#format`

All attributes except `:code` and `:subunit_to_unit` are optional.

#### Priority

You can use the `priority` attribute to sort or group currencies:

```crystal
# Returns an array of currencies where priority is less than 10
def major_currencies(currencies)
  currencies.take_while(&.priority.try(&.<(10)))
end

major_currencies(Money::Currency)
# => [#<Money::Currency @code="USD">, #<Money::Currency @code="EUR">, ...]
```

### Default Currency

By default, `Money` does not have a default currency. You can set it like so:

```crystal
Money.default_currency = :xag
```

### Currency Exponent

The exponent of a money value is the number of digits after the decimal
separator (which separates the major unit from the minor unit). See e.g.
[ISO 4217](https://www.iso.org/iso-4217-currency-codes.html) for more information.

```crystal
Money::Currency.find("USD").exponent # => 2
Money::Currency.find("JPY").exponent # => 0
Money::Currency.find("MGA").exponent # => 1
```

## Currency Exchange

Exchanging money is performed through a `Money::Currency::Exchange` object.
This is done by fetching the exchange rate from a `#rate_store` first.
If the rate is not available (or stale), it is then fetched from a `#rate_provider`.

The default `Money::Currency::Exchange` object uses `Memory` rate store
in conjunction with `Null` rate provider, which requires one to manually
specify the exchange rate.

Here's an example of how it works:

```crystal
Money.default_exchange.rate_store["USD", "EUR"] = 1.24515
Money.default_exchange.rate_store["EUR", "USD"] = 0.80311

Money.new(1_00, "USD").exchange_to("EUR") # => Money(@amount=1.24, @currency="EUR")
Money.new(1_00, "EUR").exchange_to("USD") # => Money(@amount=0.8, @currency="USD")
```

### Exchange Rate Stores

The default exchange uses an in-memory store:

```crystal
Money.default_exchange = Money::Currency::Exchange.new(
  rate_store: Money::Currency::RateStore::Memory.new
)
```

Rate stores can be configured with `Time::Span` controlling the time-to-live (TTL)
of the exchange rates:

```crystal
Money.default_exchange = Money::Currency::Exchange.new(
  rate_store: Money::Currency::RateStore::Memory.new(ttl: 1.hour)
)
```

Or use your own store (database, file, cache, etc):

```crystal
Money.default_exchange.rate_store = MyCustomStore.new
```

The store can be used directly:

```crystal
# Add to the underlying store
Money.default_exchange.rate_store["USD", "CAD"] = 0.9

# Retrieve from the underlying store
Money.default_exchange.rate_store["USD", "CAD"] # => 0.9
```

As long as the store holds the exchange rates, `Money` will use them.

```crystal
Money.new(10_00, "USD").exchange_to("CAD")        # => Money(@amount=9.0 @currency="CAD")
Money.new(10_00, "CAD") + Money.new(10_00, "USD") # => Money(@amount=19.0 @currency="CAD")
```

### Exchange Rate Providers

By default, the exchange uses a `Null` provider, which returns `nil` for all rates.

```crystal
Money.default_exchange = Money::Currency::Exchange.new(
  rate_provider: Money::Currency::RateProvider::Null.new
)
```

There are multiple providers available under the `Money::Currency::RateProvider`
[namespace](https://github.com/crystal-money/money/tree/master/src/money/currency/rate_provider)
which can be used OOTB to fetch exchange rates from different sources.

You can choose one of them, roll your own, or combine them with the `Compound` provider:

```crystal
Money.default_exchange.rate_provider =
  Money::Currency::RateProvider::Compound.new([
    Money::Currency::RateProvider::ECB.new,
    Money::Currency::RateProvider::FloatRates.new,
    Money::Currency::RateProvider::UniRateAPI.new(
      api_key: "valid-api-key"
    ),
  ])
```

> [!TIP]
> `Compound` rate provider takes an array of `Money::Currency::RateProvider` instances
> which are used in order to fetch the exchange rate.

### Disabling Currency Conversion

If you want to prevent automatic currency conversion, you can do so globally:

```crystal
Money.disallow_currency_conversion!
```

Or use the block-scoped version:

```crystal
Money.disallow_currency_conversion do
  # ...
end
```

## Rounding

By default, `Money` rounds to the nearest cent:

```crystal
Money.new(2.34567, "USD").format # => "$2.35"
```

You can change the rounding precision:

```crystal
Money.new(2.34567, "USD").round(1).format # => "$2.30"
```

You can change the rounding mode:

```crystal
Money.new(2.34567, "USD").round(1, :to_positive).format # => "$2.40"
Money.new(2.34567, "USD").round(1, :to_negative).format # => "$2.30"
```

To keep extra digits, enable infinite precision:

```crystal
Money.infinite_precision = true

Money.new(2.34567, "USD").format                    # => "$2.34567"
Money.new(2.34567, "USD").round(4).format           # => "$2.3457"
Money.new(2.34567, "USD").round(4, :to_zero).format # => "$2.3456"

# or

Money.with_rounding_mode(:to_zero) do
  Money.new(2.34567, "USD").round(4).format         # => "$2.3456"
end
```

### Nearest Cash Value

If you want to round to the nearest cash value, use `Money#round_to_nearest_cash_value`:

```crystal
Money.new(10_07, "CHF").round_to_nearest_cash_value
# => Money(@amount=10.05, @currency="CHF")

Money.new(10_08, "CHF").round_to_nearest_cash_value
# => Money(@amount=10.1, @currency="CHF")
```

## JSON/YAML Serialization

`Money`, `Money::Currency`, `Money::Currency::Rate` and `Money::Currency::RateProvider` implements `JSON::Serializable` and `YAML::Serializable`:

### `Money`

```crystal
Money.new(10_00, "USD").to_json # => "{\"amount\":10.0,\"currency\":\"USD\"}"
Money.new(10_00, "USD").to_yaml # => "---\namount: 10.0\ncurrency: USD\n"

Money.from_json(%({"amount": 10.0, "currency": "USD"}))
# => Money(@amount=10.0, @currency="USD")

Money.from_yaml("{ amount: 10.0, currency: USD }")
# => Money(@amount=10.0, @currency="USD")
```

### `Money::Currency`

```crystal
# Serialize existing `Money::Currency`

Money::Currency.find("USD").to_json # => "{\"code\":\"USD\", ...}"
Money::Currency.find("USD").to_yaml # => "---\ncode: USD\n ..."

# Instantiate new `Money::Currency`

Money::Currency.from_json(%({"code": "FOO", ...})) # => #<Money::Currency @code="FOO">
Money::Currency.from_yaml("{ code: FOO, ... }")    # => #<Money::Currency @code="FOO">

# Lookup existing `Money::Currency`

Money::Currency.from_json(%("USD")) # => #<Money::Currency @code="USD">
Money::Currency.from_yaml("USD")    # => #<Money::Currency @code="USD">
```

### `Money::Currency::Rate`

```crystal
rate = Money::Currency::Rate.new(
  Money::Currency.find("USD"),
  Money::Currency.find("EUR"),
  1.25.to_big_d,
  Time.parse_utc("2025-05-22", "%F"),
)

rate.to_json # => "{\"base\":\"USD\",\"target\":\"EUR\",\"value\":1.25,\"updated_at\":\"2025-05-22T00:00:00.000Z\"}"
rate.to_yaml # => "---\nbase: USD\ntarget: EUR\nvalue: 1.25\nupdated_at: 2025-05-22\n"
```

### `Money::Currency::RateProvider`

You can use `.from_json` and `.from_yaml` methods to deserialize generic
rate provider instances providing the `name` (in _CamelCase_ or _snake_case_)
and `options` - optional hash that's being passed to the provider initializer.

```crystal
provider = Money::Currency::RateProvider.from_yaml <<-YAML
  name: Compound
  options:
    providers:
    - name: ECB
    - name: FloatRates
    - name: UniRateAPI
      options:
        api_key: valid-api-key
  YAML

typeof(provider) # => Money::Currency::RateProvider
provider.class   # => Money::Currency::RateProvider::Compound
```

For specific providers you pass the `options` directly:

```crystal
compound_provider = Money::Currency::RateProvider::Compound.from_yaml <<-YAML
  providers:
  - name: ECB
  - name: FloatRates
  YAML

compound_provider.providers << Money::Currency::RateProvider::UniRateAPI.from_yaml <<-YAML
  api_key: valid-api-key
  YAML

compound_provider.providers.size # => 3
```

#### Using with `JSON::Serializable` and `YAML::Serializable`

In order to (de)serialize generic `Money::Currency::RateProvider` instances,
you need to add a `JSON/YAML::Field` annotation with a custom converter —
`Money::Currency::RateProvider::Converter`.

```crystal
class FooWithGenericProvider
  include JSON::Serializable
  include YAML::Serializable

  @[JSON::Field(converter: Money::Currency::RateProvider::Converter)]
  @[YAML::Field(converter: Money::Currency::RateProvider::Converter)]
  property provider : Money::Currency::RateProvider

  def initialize(@provider)
  end
end

foo = FooWithGenericProvider.from_yaml <<-YAML
  provider:
    name: Compound
    options:
      providers:
      - name: ECB
      - name: FloatRates
      - name: UniRateAPI
        options:
          api_key: valid-api-key
  YAML

foo.provider.class # => Money::Currency::RateProvider::Compound
```

## Working with Fibers

Global settings are being kept in a single, fiber-local `Money.context` object,
and are not shared between fibers by default.

Use this to `spawn` a fiber with the same settings as the current one:

```crystal
Money.default_currency = "EUR"

Money.spawn_with_same_context do
  Money.default_currency.code # => "EUR"
end
```

All of the `Money` APIs and classes are (or at least should be) fiber-safe.

> [!CAUTION]
> `Money.spawn_with_same_context` duplicates the `Money.context` instance,
> by calling `#dup` on it and thus only the values are being duplicated,
> references are shared.

## Formatting

There are several formatting rules for when `Money#format` is called. For more info, check out the [formatting module source](https://github.com/crystal-money/money/blob/master/src/money/money/formatting.cr), or the [docs](https://crystal-money.github.io/money/Money/Formatting.html).

Here are some examples:

```crystal
money = Money.new(1_23, "USD")    # => Money(@amount=1.23 @currency="USD")
money.format                      # => "$1.23"
money.format(sign_positive: true) # => "+$1.23"
money.format(no_cents: true)      # => "$1"
money.format(disambiguate: true)  # => "US$1.23"
money.to_s                        # => "1.23 USD"
```

If you want to format money according to the EU's [Rules for expressing monetary units](https://style-guide.europa.eu/en/content/-/isg/topic?identifier=7.3.3-rules-for-expressing-monetary-units#id370303__id370303_PositionISO):

```crystal
money = Money.new(1_23, "GBP")               # => Money(@amount=1.23 @currency="GBP")
money.format("%{currency} %{sign}%{amount}") # => "GBP 1.23"
```

## Parsing

You can parse a string with an amount and currency code or symbol:

```crystal
Money.parse("$12.34")    # => Money(@amount=12.34, @currency="USD")
Money.parse("12.34 USD") # => Money(@amount=12.34, @currency="USD")
```

## Contributors

- [Sija](https://github.com/Sija) Sijawusz Pur Rahnama (creator & maintainer)
