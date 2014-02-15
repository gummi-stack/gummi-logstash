# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "json"

# This codec may be used to decode (via inputs) and encode (via outputs) 
# full JSON messages.  If you are streaming JSON messages delimited
# by '\n' then see the `json_lines` codec.
# Encoding will result in a single JSON string.
class LogStash::Codecs::Gummi < LogStash::Codecs::Base
  config_name "gummi"

  milestone 3

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252".
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the `charset` setting to the
  # actual encoding of the text and Logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252".
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
    @map = {
      "host_name" => "string",
      "gummi_app" => "string",
      "gummi_worker" => "string",
      "gummi_output" => "integer",
      "json" => "json"
    }
  end
  
  public
  def decode(data)
    data = @converter.convert(data)

    parts = data.split(' ', @map.length)

    if parts.length < @map.length
      @logger.info("Parse failure - few parameters in data. Falling back to plain-text", :data => data)
      yield LogStash::Event.new("message" => data)
    end

    res = {}
    @map.keys.each_with_index do |key, i|
      val = parts[i].strip

      case @map[key]
      when "json"
        # try JSON parse
        if val[0] == '{'
          begin
            res[key] = JSON.parse(val)
          rescue JSON::ParserError => e
          end
        end
        res["message"] = val[0..256]

      when "integer"
        res[key] = val.to_i

      else
        res[key] = val

      end # case

    end
    yield LogStash::Event.new(res)
  end # def decode

  public
  def encode(data)
    @on_event.call(data.to_json)
  end # def encode

end # class LogStash::Codecs::JSON
