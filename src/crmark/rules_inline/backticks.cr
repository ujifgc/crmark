# Parse backticks
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Backticks

      #------------------------------------------------------------------------------
      def self.backtick(state, silent)
        pos = state.pos
        ch = state.src.charCodeAt(pos)

        return false if (ch != 0x60)  #  ` 

        start = pos
        pos  += 1
        max  = state.posMax

        while (pos < max && state.src.charCodeAt(pos) == 0x60)  # `
          pos += 1
        end

        marker = state.src[start...pos]

        matchStart = matchEnd = pos

        while matchStart = state.src.index(0x60, matchEnd) # `
          matchEnd = matchStart + 1

          while (matchEnd < max && state.src.charCodeAt(matchEnd) == 0x60) # `
            matchEnd += 1
          end

          if (matchEnd - matchStart == marker.size)
            if (!silent)
              token         = state.push("code_inline", "code", 0)
              token.markup  = String.new(marker)
              token.content = String.new(state.src[pos...matchStart]).gsub(/[ \n]+/, " ").strip.to_slice #!!!
            end
            state.pos = matchEnd
            return true
          end
        end

        state.pending += String.new(marker) if (!silent)
        state.pos     += marker.size
        return true
      end

    end
  end
end
