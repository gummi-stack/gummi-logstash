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
  def initialize(params={})
    super(params)
    @lines = LogStash::Codecs::Line.new
    @lines.charset = @charset
  end

  public
  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
    @map = {
      "host_name" => "string",
      "source" => "string",
      "app" => "string",
      "branch" => "string",
      "worker" => "string",
      "output" => "integer",
      "json" => "json" # & plain data into field message
    }
  end
  
  public
  def decode(data)

    @lines.decode(data) do |event|

      parts = event["message"].split(' ', @map.length)

      if parts.length < @map.length
        @logger.info("Parse failure - few parameters in data. Falling back to plain-text", :data => data)
        yield event
      end

      result = {}
      @map.keys.each_with_index do |key, i|
        val = parts[i].strip

        case @map[key]
        when "json"
          # try JSON parse
          if val[0] == '{'
            begin
              result[key] = JSON.parse(val)
            rescue JSON::ParserError => e
            end
          end
          result["message"] = val[0..256]

        when "integer"
          result[key] = val.to_i

        else
          result[key] = val

        end # case

      end
      yield LogStash::Event.new(result)
    end
  end # def decode

  public
  def encode(data)
    @on_event.call(data.to_json)
  end # def encode

end # class LogStash::Codecs::JSON
