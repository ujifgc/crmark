# GFM table, non-standard
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Table

      #------------------------------------------------------------------------------
      def self.getLine(state, line)
        pos = state.bMarks[line] + state.blkIndent
        max = state.eMarks[line]

        return state.src[pos, max - pos]
      end

      #------------------------------------------------------------------------------
      def self.escapedSplit(str)
        result       = [] of Bytes
        pos          = 0
        max          = str.size
        escapes      = 0
        lastPos      = 0
        backTicked   = false
        lastBackTick = 0
        
        ch           = str.charCodeAt(pos)

        while (pos < max)
          if ch == 0x60 # `
            if backTicked
              # make \` close code sequence, but not open it
              # the reason is: `\` is correct code block
              backTicked = false
              lastBackTick = pos
            elsif escapes % 2 == 0
              backTicked = true
              lastBackTick = pos
            end
          elsif (ch == 0x7c && (escapes % 2 == 0) && !backTicked)     # '|'
            result.push(str[lastPos...pos])
            lastPos = pos + 1
          end

          if (ch == 0x5c)   # '\'
            escapes += 1
          else
            escapes = 0
          end

          pos += 1
          # If there was an un-closed backtick, go back to just after
          # the last backtick, but as if it was a normal character
          if (pos == max && backTicked)
            backTicked = false
            pos = lastBackTick + 1
          end
          next if pos >= max
          ch   = str.charCodeAt(pos)
        end

        result.push(str[lastPos..-1])

        return result
      end


      #------------------------------------------------------------------------------
      def self.table(state, startLine, endLine, silent)
        # should have at least three lines
        return false if (startLine + 2 > endLine)

        nextLine = startLine + 1

        return false if (state.sCount[nextLine] < state.blkIndent)

        # first character of the second line should be '|', '-', ':',
        # and no other characters are allowed but spaces;
        # basically, this is the equivalent of /^[-:|][-:|\s]*$/ regexp
        pos = state.bMarks[nextLine] + state.tShift[nextLine]
        return false if (pos >= state.eMarks[nextLine])

        ch = state.src.charCodeAt(pos)
        pos += 1
        return false if (ch != 0x7C && ch != 0x2D && ch != 0x3A) # != '|' && '-' && ':'

        while pos < state.eMarks[nextLine]
          ch = state.src.charCodeAt(pos)
          return false if (ch != 0x7C && ch != 0x2D && ch != 0x3A && !ch.space_tab?) # != '|' && '-' && ':'
          pos += 1
        end

        lineText = getLine(state, startLine + 1)

        columns = String.new(lineText).split("|").map(&.to_slice)

        aligns = [] of String
        (0...columns.size).each do |i|
          t = columns[i].strip
          if t.empty?
            # allow empty columns before and after table, but not in between columns
            # e.g. allow ` |---| `, disallow ` ---||--- `
            if (i == 0 || i == columns.size - 1)
              next
            else
              return false
            end
          end

          return false if (t.bytematch(/^:?-+:?$/)).nil?
          if (t.charCodeAt(t.size - 1) == 0x3A)  # ':'
            aligns.push(t.charCodeAt(0) == 0x3A ? "center" : "right")
          elsif (t.charCodeAt(0) == 0x3A)
            aligns.push("left")
          else
            aligns.push("")
          end
        end

        lineText = getLine(state, startLine).strip
        return false if !lineText.includes?('|'.ord)
        columns = self.escapedSplit(String.new(lineText).gsub(/^\||\|$/, "").to_slice)

        # header row will define an amount of columns in the entire table,
        # and align row shouldn't be smaller than that (the rest of the rows can)
        columnCount = columns.size
        return false if columnCount > aligns.size
        return true  if silent

        token     = state.push(:table_open, "table", 1)
        token.map = tableLines = [ startLine, 0 ]

        token     = state.push(:thead_open, "thead", 1)
        token.map = [ startLine, startLine + 1 ]

        token     = state.push(:tr_open, "tr", 1)
        token.map = [ startLine, startLine + 1 ]

        (0...columns.size).each do |i|
          token          = state.push(:th_open, "th", 1)
          token.map      = [ startLine, startLine + 1 ]
          unless aligns[i].empty?
            token.attrs  = [ [ "style", "text-align:" + aligns[i] ] ]
          end

          token          = state.push(:inline, "", 0)
          token.content  = columns[i].strip
          token.map      = [ startLine, startLine + 1 ]
          token.children = [] of Token

          token          = state.push(:th_close, "th", -1)
        end

        token     = state.push(:tr_close, "tr", -1)
        token     = state.push(:thead_close, "thead", -1)

        token     = state.push(:tbody_open, "tbody", 1)
        token.map = tbodyLines = [ startLine + 2, 0 ]

        nextLine = startLine + 2
        while nextLine < endLine
          break if (state.sCount[nextLine] < state.blkIndent)

          lineText = getLine(state, nextLine)
          break if !lineText.includes?('|'.ord)
          # keep spaces at beginning of line to indicate an empty first cell, but
          # strip trailing whitespace
          columns = self.escapedSplit(String.new(lineText).gsub(/^\||\|\s*$/, "").to_slice)

          token = state.push(:tr_open, "tr", 1)
          (0...columnCount).each do |i|
            token          = state.push(:td_open, "td", 1)
            unless aligns[i].empty?
              token.attrs  = [ [ "style", "text-align:" + aligns[i] ] ]
            end

            token          = state.push(:inline, "", 0)
            token.content  = columns[i]? ? columns[i].strip : "".to_slice
            token.children = [] of Token

            token          = state.push(:td_close, "td", -1)
          end
          token = state.push(:tr_close, "tr", -1)
          nextLine += 1
        end
        token = state.push(:tbody_close, "tbody", -1)
        token = state.push(:table_close, "table", -1)

        tableLines[1] = tbodyLines[1] = nextLine
        state.line = nextLine
        return true
      end

    end
  end
end
