# HTML block
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class HtmlBlock
      # An array of opening and corresponding closing sequences for html tags,
      # last argument defines whether it can terminate a paragraph or not
      #
      HTML_SEQUENCES = [
        { /^<(script|pre|style)(?=(\s|>|$))/i, /<\/(script|pre|style)>/i, true },
        { /^<!--/,        /-->/,   true },
        { /^<\?/,         /\?>/,   true },
        { /^<![A-Z]/,     />/,     true },
        { /^<!\[CDATA\[/, /\]\]>/, true },
        { Regex.new("^</?(" + HTML_BLOCKS.keys.join('|') + ")(?=(\\s|/?>|$))", Regex::Options::IGNORE_CASE), /^$/, true },
        { Regex.new(Common::HtmlRe::HTML_OPEN_CLOSE_TAG_RE.source + "\\s*$"),  /^$/, false }
      ]

      #------------------------------------------------------------------------------
      def self.html_block(state, startLine, endLine, silent)
        pos = state.bMarks[startLine] + state.tShift[startLine]
        max = state.eMarks[startLine]

        return false if !state.md.options[:html]

        return false if state.src[pos] != 0x3C # <

        lineText = state.src[pos...max]

        i = 0
        while i < HTML_SEQUENCES.size
          break if HTML_SEQUENCES[i][0].bytematch(lineText)
          i += 1
        end

        return false if i == HTML_SEQUENCES.size

        # true if this sequence can be a terminator, false otherwise
        return HTML_SEQUENCES[i][2] if silent

        nextLine = startLine + 1

        # If we are here - we detected HTML block.
        # Let's roll down till block end.
        unless HTML_SEQUENCES[i][1].bytematch(lineText)
          while nextLine < endLine
            break if state.sCount[nextLine] < state.blkIndent

            pos = state.bMarks[nextLine] + state.tShift[nextLine]
            max = state.eMarks[nextLine]
            lineText = state.src[pos...max]

            if HTML_SEQUENCES[i][1].bytematch(lineText)
              nextLine += 1 if lineText.size > 0
              break
            end
            nextLine += 1
          end
        end

        state.line = nextLine

        token         = state.push(:html_block, "", 0)
        token.map     = [ startLine, nextLine ]
        token.content = state.getLines(startLine, nextLine, state.blkIndent, true)

        true
      end

    end
  end
end
