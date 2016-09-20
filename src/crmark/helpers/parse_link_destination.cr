# Parse link destination
#------------------------------------------------------------------------------
module MarkdownIt
  module Helpers
    module ParseLinkDestination
      
      #------------------------------------------------------------------------------
      def parseLinkDestination(str, pos, max) : NamedTuple(ok: Bool, pos: Int32, lines: Int32, str: String)
        lines = 0
        start = pos
        result = {ok: false, pos: 0, lines: 0, str: ""}

        return result if start >= max

        if (str.charCodeAt(pos) == 0x3C ) # < 
          pos += 1
          while (pos < max)
            code = str.charCodeAt(pos)
            return result if (code == 0x0A ) # \n
            if (code == 0x3E) #  >
              return {ok: true, pos: pos+1, lines: 0, str: unescapeAll(str[(start + 1)...pos])}
            end
            if (code == 0x5C && pos + 1 < max)  # \
              pos += 2
              next
            end

            pos += 1
          end

          # no closing '>'
          return result
        end

        # this should be ... } else { ... branch

        level = 0
        while (pos < max) 
          code = str.charCodeAt(pos)

          break if (code == 0x20)

          # ascii control characters
          break if (code < 0x20 || code == 0x7F)

          if (code == 0x5C && pos + 1 < max) # \
            pos += 2
            next
          end

          if (code == 0x28) # (
            level += 1
            break if (level > 1)
          end

          if (code == 0x29) # )
            level -= 1
            break if (level < 0)
          end

          pos += 1
        end

        return result if start == pos

        return {ok: true, pos: pos, lines: lines, str: unescapeAll(str[start...pos])}
      end
    end
  end
end