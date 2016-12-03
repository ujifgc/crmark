module MarkdownIt
  module MDUrl
    module Encode
      DEFAULT_CHARACTERS   = ";/?:@&=+$,-_.!~*'()#"
      COMPONENT_CHARACTERS = "-_.!~*'()"

      @@encodeCache = {} of String => Array(String)

      # Create a lookup array where anything but characters in `chars` string
      # and alphanumeric chars is percent-encoded.
      #------------------------------------------------------------------------------
      def self.getEncodeCache(exclude)
        cache = @@encodeCache[exclude]?
        return cache if cache

        cache = @@encodeCache[exclude] = [] of String

        (0...128).each do |i|
          ch = i.chr

          if ch.to_s.match(/^[0-9a-z]$/i)
            # always allow unencoded alphanumeric characters
            cache.push(ch.to_s)
          else
            cache.push("%" + ("0" + i.to_s(16).upcase)[-2, 2])
          end
        end

        (0...exclude.size).each do |i|
          cache[exclude[i].ord] = exclude[i].to_s
        end

        return cache
      end

      # Encode unsafe characters with percent-encoding, skipping already
      # encoded sequences.
      #
      #  - string       - string to encode
      #  - exclude      - list of characters to ignore (in addition to a-zA-Z0-9)
      #  - keepEscaped  - don't encode '%' in a correct escape sequence (default: true)
      #------------------------------------------------------------------------------
      def self.encode(string, exclude : String = DEFAULT_CHARACTERS, keepEscaped : Bool = true)
        result = ""

        cache = getEncodeCache(exclude)

        i = 0
        l = string.size
        while i < l
          code = string[i].ord

          if (keepEscaped && code == 0x25 && i + 2 < l) #  %
            if (/^[0-9a-f]{2}$/i).match(string[(i + 1)...(i + 3)])
              result += string[i...(i + 3)]
              i += 3
              next
            end
          end

          if (code < 128)
            result += cache[code]
            i += 1
            next
          end

          if (code >= 0xD800 && code <= 0xDFFF)
            if (code >= 0xD800 && code <= 0xDBFF && i + 1 < l)
              nextCode = string[i + 1].ord
              if (nextCode >= 0xDC00 && nextCode <= 0xDFFF)
                result += URI.escape(string[i].to_s + string[i + 1].to_s)
                i += 2
                next
              end
            end
            result += "%EF%BF%BD"
            i += 1
            next
          end

          result += URI.escape(string[i].to_s)
          i += 1
        end

        return result
      end
    end
  end
end
