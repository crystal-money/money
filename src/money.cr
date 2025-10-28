require "big"
require "json"
{% if flag?(:docs) %}
  require "yaml"
{% end %}
require "tssc"
require "atomic_write"

struct Money
end

require "./core_ext/**"
require "./money/error"
require "./money/registry"
require "./money/*"
