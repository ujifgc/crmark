# Parse link title
#------------------------------------------------------------------------------
module MarkdownIt
  module Helpers
    module ParseLinkTitle

      #------------------------------------------------------------------------------
      def parseLinkTitle(str, pos, max) : NamedTuple(ok: Bool, pos: Int32, lines: Int32, str: Bytes)
        lines = 0
        start = pos
        result = {ok: false, pos: 0, lines: 0, str: Bytes.empty}

        return result if (pos >= max)

        marker = str[pos]

        return result if (marker != 0x22 && marker != 0x27 && marker != 0x28) # " ' (

        pos += 1

        # if opening marker is "(", switch it to closing marker ")"
        marker = 0x29 if (marker == 0x28)

        while (pos < max)
          code = str[pos]
          if (code == marker)
            return {ok: true, pos: pos+1, lines: lines, str: unescapeAll(str[(start + 1)...pos])}
          elsif (code == 0x0A)
            lines += 1
          elsif (code == 0x5C && pos + 1 < max) # \
            pos += 1
            if (str[pos] == 0x0A)
              lines += 1
            end
          end

          pos += 1
        end

        result
      end
    end
  end
end
