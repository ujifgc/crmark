# lheading (---, ===)
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Lheading

      #------------------------------------------------------------------------------
      def self.lheading(state, startLine, endLine, silent = true)
        nextLine = startLine + 1
        terminatorRules = state.md.block.ruler.getRules("paragraph")

        # if it's indented more than 3 spaces, it should be a code block
        return false if state.sCount[startLine] - state.blkIndent >= 4

        oldParentType = state.parentType
        state.parentType = "paragraph"

        marker = 0

        # jump line-by-line until empty one or EOF
        while nextLine < endLine && !state.isEmpty(nextLine)
          # this would be a code block normally, but after paragraph
          # it's considered a lazy continuation regardless of what's there
          if state.sCount[nextLine] - state.blkIndent > 3
            nextLine += 1
            next
          end

          #
          # Check for underline in setext header
          #
          if state.sCount[nextLine] >= state.blkIndent
            pos = state.bMarks[nextLine] + state.tShift[nextLine]
            max = state.eMarks[nextLine]

            if pos < max
              marker = state.src[pos]

              if marker == 0x2D || marker == 0x3D # - or =
                pos = state.skipChars(pos, marker)
                pos = state.skipSpaces(pos)

                if pos >= max
                  level = (marker == 0x3D ? 1 : 2) # =
                  break
                end
              end
            end
          end

          # quirk for blockquotes, this line should already be checked by that rule
          if state.sCount[nextLine] < 0
            nextLine += 1
            next
          end

          # Some tags can terminate paragraph without empty line.
          terminate = false
          (0...terminatorRules.size).each do |i|
            if terminatorRules[i].call(state, nextLine, endLine, true)
              terminate = true
              break
            end
          end
          break if terminate

          nextLine += 1
        end

        # Didn't find valid underline
        return false if !level

        content = state.getLines(startLine, nextLine, state.blkIndent, false).strip

        state.line = nextLine + 1

        token          = state.push(:heading_open, "h" + level.to_s, 1)
        token.markup   = marker.chr.to_s
        token.map      = [ startLine, state.line ]

        token          = state.push(:inline, "", 0);
        token.content  = content
        token.map      = [ startLine, state.line - 1 ]
        token.children = [] of Token

        token          = state.push(:heading_close, "h" + level.to_s, -1)
        token.markup   = marker.chr.to_s

        state.parentType = oldParentType

        true
      end

    end
  end
end
