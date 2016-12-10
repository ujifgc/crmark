# heading (#, ##, ...)
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Heading

      #------------------------------------------------------------------------------
      def self.heading(state, startLine, endLine, silent)
        pos = state.bMarks[startLine] + state.tShift[startLine]
        max = state.eMarks[startLine]
        ch  = state.src[pos]

        return false if (ch != 0x23 || pos >= max)

        # count heading level
        level = 1
        pos  += 1
        ch = state.src[pos]
        while (ch == 0x23 && pos < max && level <= 6)  # '#'
          level += 1
          pos   += 1
          ch = state.src[pos]
        end

        return false if (level > 6 || (pos < max && ch != 0x20 && ch != 0x09))  # space/tab

        return true if (silent)

        # Let's cut tails like '    ###  ' from the end of string

        max = state.skipSpacesBack(max, pos) # space
        tmp = state.skipCharsBack(max, 0x23, pos) # '#'
        ch  = state.src[tmp - 1]
        if (tmp > pos && (ch == 0x20 || ch == 0x09))   # space/tab
          max = tmp
        end

        state.line = startLine + 1

        token          = state.push(:heading_open, "h#{level.to_s}", 1)
        token.markup   = "########"[0...level]
        token.map      = [ startLine, state.line ]

        token          = state.push(:inline, "", 0)
        token.content  = state.src[pos...max].strip
        token.map      = [ startLine, state.line ]
        token.children = [] of Token

        token        = state.push(:heading_close, "h#{level.to_s}", -1)
        token.markup = "########"[0...level]

        return true
      end

    end
  end
end
