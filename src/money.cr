require "big"
require "json"
{% if flag?(:docs) %}
  require "yaml"
{% end %}
require "tssc"

struct Money
end

require "./core_ext/**"
require "./money/error"
require "./money/registry"
require "./money/*"
