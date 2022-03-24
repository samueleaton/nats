require "http/headers"

def HTTP::Headers.from_json(string_or_io)
  h = self.new
  pull = JSON::PullParser.new(string_or_io)
  pull.read_object do |key, key_location|
    parsed_key = String.from_json_object_key?(key)
    unless parsed_key
      raise JSON::ParseException.new("Can't convert #{key.inspect} into String", *key_location)
    end
    h.add parsed_key, (String | Array(String)).new(pull)
  end
  h
end
