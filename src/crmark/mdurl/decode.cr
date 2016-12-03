module MarkdownIt
  module MDUrl
    module Decode
      @@decodeCache = {} of String => Array(String)

      DEFTAULT_CHARS   = ";/?:@&=+$,#"
      COMPONENT_CHARS  = ""

      #------------------------------------------------------------------------------
      def self.getDecodeCache(exclude)
        cache = @@decodeCache[exclude]?
        return cache if cache

        cache = @@decodeCache[exclude] = [] of String

        (0...128).each do |i|
          ch = i.chr
          cache.push(ch.to_s)
        end

        (0...exclude.size).each do |i|
          ch = exclude[i].ord
          cache[ch] = "%" + ("0" + ch.to_s(16).upcase)[-2, 2]
        end

        return cache
      end


      # Decode percent-encoded string.
      #------------------------------------------------------------------------------
      def self.decode(string, exclude = nil)
        if !exclude.is_a? String
          exclude = DEFTAULT_CHARS
        end

        cache = getDecodeCache(exclude)

        return string.gsub(/(%[a-f0-9]{2})+/i) do |seq|
          result = ""

          i = 0
          l = seq.size
          while i < l
            b1 = seq[(i + 1)...(i + 3)].to_i(16)

            if b1 < 0x80
              result += cache[b1]
              i += 3
              next
            end

            if ((b1 & 0xE0) == 0xC0 && (i + 3 < l))
              # 110xxxxx 10xxxxxx
              b2 = seq[(i + 4)...(i + 6)].to_i(16)

              if ((b2 & 0xC0) == 0x80)
                char = ((b1 << 6) & 0x7C0) | (b2 & 0x3F)

                if (char < 0x80)
                  result += "\ufffd\ufffd"
                else
                  result += char.chr #(Encoding::UTF_8)
                end

                i += 6
                next
              end
            end

            if ((b1 & 0xF0) == 0xE0 && (i + 6 < l))
              # 1110xxxx 10xxxxxx 10xxxxxx
              b2 = seq[(i + 4)...(i + 6)].to_i(16)
              b3 = seq[(i + 7)...(i + 9)].to_i(16)

              if ((b2 & 0xC0) == 0x80 && (b3 & 0xC0) == 0x80)
                char = ((b1 << 12) & 0xF000) | ((b2 << 6) & 0xFC0) | (b3 & 0x3F)

                if (char < 0x800 || (char >= 0xD800 && char <= 0xDFFF))
                  result += "\ufffd\ufffd\ufffd"
                else
                  result += char.chr #(Encoding::UTF_8)
                end

                i += 9
                next
              end
            end

            if ((b1 & 0xF8) == 0xF0 && (i + 9 < l))
              # 111110xx 10xxxxxx 10xxxxxx 10xxxxxx
              b2 = seq[(i + 4)...(i + 6)].to_i(16)
              b3 = seq[(i + 7)...(i + 9)].to_i(16)
              b4 = seq[(i + 10)...(i + 12)].to_i(16)

              if ((b2 & 0xC0) == 0x80 && (b3 & 0xC0) == 0x80 && (b4 & 0xC0) == 0x80)
                char = ((b1 << 18) & 0x1C0000) | ((b2 << 12) & 0x3F000) | ((b3 << 6) & 0xFC0) | (b4 & 0x3F)

                if (char < 0x10000 || char > 0x10FFFF)
                  result += "\ufffd\ufffd\ufffd\ufffd"
                else
                  # TODO don't know how to handle surrogate pairs properly.
                  char   -= 0x10000
                  result += [0xD800 + (char >> 10), 0xDC00 + (char & 0x3FF)].map{|c| c.chr}.join

                  # high = ((char - 0x10000) / 0x400).floor + 0xD800
                  # low  = ((char - 0x10000) % 0x400) + 0xDC00
                  # result += "\u" + [high, low].map { |x| x.to_s(16) }.join("\u").downcase
                end

                i += 12
                next
              end
            end

            result += "\ufffd"
            i += 3
          end

          result
        end
      end

    end
  end
end
