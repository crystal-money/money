require "json"

class Money::Currency
  JSON.mapping({
    priority:              {type: Int32, setter: false},
    iso_numeric:           {type: UInt32?, setter: false},
    code:                  {type: String, setter: false},
    name:                  {type: String, setter: false},
    symbol:                {type: String?, setter: false},
    alternate_symbols:     {type: Array(String)?, setter: false},
    subunit:               {type: String?, setter: false},
    subunit_to_unit:       {type: UInt64, setter: false},
    symbol_first?:         {type: Bool, setter: false},
    html_entity:           {type: String?, setter: false},
    decimal_mark:          {type: String?, setter: false},
    thousands_separator:   {type: String?, setter: false},
    smallest_denomination: {type: UInt32?, setter: false},
  })

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when :string
      find(pull.read_string)
    else
      previous_def
    end
  end
end
