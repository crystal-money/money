class Money::Currency
  abstract class RateProvider
    # All registered rate providers.
    class_getter providers = {} of String => RateProvider.class

    macro inherited
      {% @type.raise "abstract rate providers are not allowed" if @type.abstract? %}
      {%
        superclass_name = @type.superclass.name
        name = @type.name
        name =
          if name.starts_with?("#{superclass_name}::")
            name[superclass_name.size + 2..].underscore
          else
            @type.raise "class must be placed inside `#{superclass_name}` namespace"
          end
      %}
      {{ superclass_name }}.providers[{{ name.stringify }}] = self

      # Returns the provider key.
      def self.key : String
        {{ name.stringify }}
      end
    end

    if_defined?(:JSON) do
      include JSON::Serializable

      # :nodoc:
      #
      # This method will be replaced by `JSON::Serializable` for each
      # descendant rate provider class.
      def self.new(pull : JSON::PullParser)
        raise "unreachable"
      end
    end

    if_defined?(:YAML) do
      include YAML::Serializable

      # :nodoc:
      #
      # This method will be replaced by `YAML::Serializable` for each
      # descendant rate provider class.
      def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
        raise "unreachable"
      end
    end

    # Returns the rate provider class for the given *name* if found,
    # `nil` otherwise.
    def self.find?(name : String) : RateProvider.class | Nil
      providers[name.underscore]?
    end

    # Returns the rate provider class for the given *name* if found,
    # raises `UnknownRateProviderError` otherwise.
    def self.find(name : String) : RateProvider.class
      find?(name) ||
        raise UnknownRateProviderError.new(name)
    end

    # Returns the value of the environment variable *key* or raises
    # `RateProviderRequiredOptionError` if the variable is not set.
    protected def option_from_env(key : String) : String
      ENV[key]? ||
        raise RateProviderRequiredOptionError.new \
          "Environment variable #{key.inspect} is required"
    end

    # Returns an array of supported base currency codes.
    abstract def base_currency_codes : Array(String)

    # Returns an array of supported target currency codes.
    def target_currency_codes : Array(String)
      base_currency_codes
    end

    # Returns the exchange rate between *base* and *target* currency, or `nil` if not found.
    abstract def exchange_rate?(base : Currency, target : Currency) : Rate?

    # Returns `true` if the provider supports the given currency pair.
    def supports_currency_pair?(base : Currency, target : Currency) : Bool
      base_currency_codes.includes?(base.code) &&
        target_currency_codes.includes?(target.code)
    end
  end
end

require "./rate_provider/http"
require "./rate_provider/*"
