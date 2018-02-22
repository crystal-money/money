# money [![Build Status](https://travis-ci.org/crystal-money/money.svg?branch=master)](https://travis-ci.org/crystal-money/money)

## Introduction

A Crystal shard for dealing with money and currency conversion ported from [RubyMoney](https://github.com/RubyMoney/money).

### Features

- Provides a `Money` class which encapsulates all information about an certain
  amount of money, such as its value and its currency.
- Provides a `Money::Currency` class which encapsulates all information about
  a monetary unit.
- Represents monetary values as integers, in cents. This avoids floating point
  rounding errors.
- Represents currency as `Money::Currency` instances providing a high level of
  flexibility.
- Provides APIs for exchanging money from one currency to another.

### Resources

- [API Documentation](https://crystal-money.github.io/money/)
- [Git Repository](https://github.com/crystal-money/money)

### Notes

- Your app must use UTF-8 to function with this library. There are a
  number of non-ASCII currency attributes.
- This app requires JSON.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  money:
    github: crystal-money/money
```

Install with `shards install`.

## Usage

```crystal
require "money"

# 10.00 USD
money = Money.new(1000, "USD")
money.cents    # => 1000
money.currency # => Money::Currency.find("USD")

# Comparisons
Money.new(1000, "USD") == Money.new(1000, "USD") # => true
Money.new(1000, "USD") == Money.new(100,  "USD") # => false
Money.new(1000, "USD") == Money.new(1000, "EUR") # => false
Money.new(1000, "USD") != Money.new(1000, "EUR") # => true

# Arithmetic
Money.new(1000, "USD") + Money.new(500, "USD") == Money.new(1500, "USD")
Money.new(1000, "USD") - Money.new(200, "USD") == Money.new(800,  "USD")
Money.new(1000, "USD") / 5                     == Money.new(200,  "USD")
Money.new(1000, "USD") * 5                     == Money.new(5000, "USD")

# Unit to subunit conversions
Money.from_amount(5, "USD") == Money.new(500,  "USD") # 5 USD
Money.from_amount(5, "JPY") == Money.new(5,    "JPY") # 5 JPY
Money.from_amount(5, "TND") == Money.new(5000, "TND") # 5 TND

# Currency conversions
some_code_to_setup_exchange_rates
Money.new(1000, "USD").exchange_to("EUR") == Money.new(some_value, "EUR")

# Formatting (see Formatting section for more options)
Money.new(100, "USD").format # => "$1.00"
Money.new(100, "GBP").format # => "£1.00"
Money.new(100, "EUR").format # => "€1.00"
```

## Currency

Currencies are consistently represented as instances of `Money::Currency`.
The most part of `Money` APIs allows you to supply either a `String`, `Symbol`
or a `Money::Currency`.

```crystal
Money.new(1000, "USD") == Money.new(1000, Money::Currency.find("USD"))
Money.new(1000, "EUR").currency == Money::Currency.find(:eur)
Money.new(1000, "PLN").currency == Money::Currency[:pln]
```

A `Money::Currency` instance holds all the information about the currency,
including the currency symbol, name and much more.

```crystal
currency = Money.new(1000, "USD").currency
currency.code # => "USD"
currency.name # => "United States Dollar"
```

To define a new `Money::Currency` use `Money::Currency.register` as shown
below.

```crystal
currency = Money::Currency.from_json({
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
}.to_json)

Money::Currency.register(currency)
```

The pre-defined set of attributes includes:

- `:priority` a numerical value you can use to sort/group the currency list
- `:code` the international 3-letter code as defined by the ISO 4217 standard
- `:iso_numeric` the international 3-digit code as defined by the ISO 4217 standard
- `:name` the currency name
- `:symbol` the currency symbol (UTF-8 encoded)
- `:symbol_first` whether a money symbol should go before the amount
- `:subunit` the name of the fractional monetary unit
- `:subunit_to_unit` the proportion between the unit and the subunit
- `:decimal_mark` character between the whole and fraction amounts
- `:thousands_separator` character between each thousands place

All attributes except `:code` and `:subunit_to_unit` are optional.
Some attributes, such as `:symbol`, are used by the `Money` class to print out a
representation of the object. Other attributes, such as `:name` or `:priority`,
exist to provide a basic API you can take advantage of to build your application.

### :priority

The priority attribute is an arbitrary numerical value you can assign to the
`Money::Currency` and use in sorting/grouping operation.

For instance, let's assume your web application needs to render a currency
selector like the one available
[here](https://finance.yahoo.com/currency-converter/). You can create a couple of
custom methods to return the list of major currencies and all currencies as
follows:

```crystal
# Returns an array of currency id where priority < 10
def major_currencies(hash)
  hash.values.sort.take_while(&.priority.try(&.<(10))).map(&.id)
end

# Returns an array of all currency id
def all_currencies(hash)
  hash.keys
end

major_currencies(Money::Currency.table)
# => ["usd", "eur", "gbp", "aud", "cad", "jpy"]

all_currencies(Money::Currency.table)
# => ["aed", "afn", "all", ...]
```

### Default Currency

By default `Money` defaults to USD as its currency. This can be overwritten
using:

```crystal
Money.default_currency = Money::Currency.find("CAD")
# or
Money.default_currency = :cad
```

### Currency Exponent

The exponent of a money value is the number of digits after the decimal
separator (which separates the major unit from the minor unit). See e.g.
[ISO 4217](https://www.currency-iso.org/en/shared/amendments/iso-4217-amendment.html) for more
information. You can find the exponent (as an `Int32`) by

```crystal
Money::Currency.find("USD").exponent # => 2
Money::Currency.find("JPY").exponent # => 0
Money::Currency.find("MGA").exponent # => 1
```

### Currency Lookup

To find a given currency by ISO 4217 numeric code (three digits) you can do

```crystal
Money::Currency.find(&.iso_numeric.==(978)) # => Money::Currency.find(:eur)
```

## Currency Exchange

Exchanging money is performed through an exchange `Bank` object. The default
exchange `Bank` object requires one to manually specify the exchange rate. Here's
an example of how it works:

```crystal
Money.default_bank.store["USD", "EUR"] = 1.24515
Money.default_bank.store["EUR", "USD"] = 0.803115

Money.new(100, "USD").exchange_to("EUR") # => Money.new(124, "EUR")
Money.new(100, "EUR").exchange_to("USD") # => Money.new(80,  "USD")
```

Comparison and arithmetic operations work as expected:

```crystal
Money.new(1000, "USD") <=> Money.new(900, "USD") # => 1; 9.00 USD is smaller
Money.new(1000, "EUR") + Money.new(10, "EUR") == Money.new(1010, "EUR")

Money.default_bank.store["USD", "EUR"] = 0.5
Money.new(1000, "EUR") + Money.new(1000, "USD") == Money.new(1500, "EUR")
```

### Exchange rate stores

The default bank is initialized with an in-memory store for exchange rates.

```crystal
Money.default_bank = Money::Bank::VariableExchange.new(Money::Currency::RateStore::Memory.new)
```

You can pass you own store implementation, ie. for storing and retrieving rates off a database, file, cache, etc.

```crystal
Money.default_bank = Money::Bank::VariableExchange.new(MyCustomStore.new)

# Add to the underlying store
Money.default_bank.store["USD", "CAD"] = 0.9

# Retrieve from the underlying store
Money.default_bank.store["USD", "CAD"] # => 0.9

# Exchanging amounts just works
Money.new(1000, "USD").exchange_to("CAD") # => #<Money @fractional=900 @currency="CAD">
```

There is nothing stopping you from creating store objects which scrapes
[XE](http://www.xe.com) for the current rates or just returns `rand(2)`:

```crystal
Money.default_bank = Money::Bank::VariableExchange.new(StoreWhichScrapesXeDotCom.new)
```

You can also implement your own `Bank` to calculate exchanges differently.
Different banks can share Stores.

```crystal
Money.default_bank = MyCustomBank.new(Money::Currency::RateStore::Memory.new)
```

If you wish to disable automatic currency conversion to prevent arithmetic when
currencies don't match:

```crystal
Money.disallow_currency_conversion!
```

## Formatting

There are several formatting rules for when `Money#format` is called. For more information, check out the [formatting module source](https://github.com/crystal-money/money/blob/master/src/money/money/formatting.cr), or read the latest release's [docs](http://crystal-money.github.io/money/Money/Formatting.html).

If you wish to format money according to the EU's [Rules for expressing monetary units](http://publications.europa.eu/code/en/en-370303.htm#position) in either English, Irish, Latvian or Maltese:

```crystal
money = Money.new(123, :gbp)               # => #<Money @fractional=123 @currency="GBP">
money.format(symbol: "#{money.currency} ") # => "GBP 1.23"
```

## Heuristics

To parse a `String` containing amount with currency code or symbol you can do

```crystal
Money.parse("$12.34")    == Money.from_amount(12.34, "USD")
Money.parse("12.34 USD") == Money.from_amount(12.34, "USD")
```

## Contributors

- [Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer

## Thanks

Thanks to all of the [contributors](https://github.com/RubyMoney/money/blob/master/AUTHORS) for their awesome work on [RubyMoney](https://github.com/RubyMoney/money).
