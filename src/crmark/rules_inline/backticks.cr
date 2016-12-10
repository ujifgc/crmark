# Parse backticks
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Backticks

      #------------------------------------------------------------------------------
      def self.backtick(state, silent)
        pos = state.pos
        ch = state.src[pos]

        return false if (ch != 0x60)  #  ` 

        start = pos
        pos  += 1
        max  = state.posMax

        while (pos < max && state.src[pos] == 0x60)  # `
          pos += 1
        end

        marker = state.src[start...pos]

        matchStart = matchEnd = pos

        while matchStart = state.src.index(0x60, matchEnd) # `
          matchEnd = matchStart + 1

          while (matchEnd < max && state.src[matchEnd] == 0x60) # `
            matchEnd += 1
          end

          if (matchEnd - matchStart == marker.size)
            if (!silent)
              token         = state.push(:code_inline, "code", 0)
              token.markup  = String.new(marker)
              token.content = /[ \n]+/.bytegsub(state.src[pos...matchStart], ' ').strip
            end
            state.pos = matchEnd
            return true
          end
        end

        state.pending.write marker if !silent
        state.pos += marker.size
        return true
      end

    end
  end
end
