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
        result       = [] of String
        pos          = 0
        max          = str.size
        escapes      = 0
        lastPos      = 0
        backTicked   = false
        lastBackTick = 0
        
        ch           = str.charCodeAt(pos)

        while (pos < max)
          if (ch == 0x60 && (escapes % 2 == 0))  # `
            backTicked   = !backTicked
            lastBackTick = pos
          elsif (ch == 0x7c && (escapes % 2 == 0) && !backTicked)     # '|'
            result.push(str[lastPos...pos])
            lastPos = pos + 1
          elsif (ch == 0x5c)   # '\'
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
          ch   = str.charCodeAt(pos)
        end

        result.push(str.slice_to_end(lastPos))

        return result
      end


      #------------------------------------------------------------------------------
      def self.table(state, startLine, endLine, silent)
        # should have at least three lines
        return false if (startLine + 2 > endLine)

        nextLine = startLine + 1

        return false if (state.sCount[nextLine] < state.blkIndent)

        # first character of the second line should be '|' or '-'
        pos = state.bMarks[nextLine] + state.tShift[nextLine]
        return false if (pos >= state.eMarks[nextLine])

        ch = state.src.charCodeAt(pos)
        return false if (ch != 0x7C && ch != 0x2D && ch != 0x3A) # != '|' && '-' && ':'

        lineText = getLine(state, startLine + 1)
        return false if (/^[-:| ]+$/ =~ lineText).nil?

        rows = lineText.split("|")
        return false if (rows.size < 2)
        aligns = [] of String
        (0...rows.size).each do |i|
          t = rows[i].strip
          if t.empty?
            # allow empty columns before and after table, but not in between columns
            # e.g. allow ` |---| `, disallow ` ---||--- `
            if (i == 0 || i == rows.size - 1)
              next
            else
              return false
            end
          end

          return false if (/^:?-+:?$/ =~ t).nil?
          if (t.charCodeAt(t.size - 1) == 0x3A)  # ':'
            aligns.push(t.charCodeAt(0) == 0x3A ? "center" : "right")
          elsif (t.charCodeAt(0) == 0x3A)
            aligns.push("left")
          else
            aligns.push("")
          end
        end

        lineText = getLine(state, startLine).strip
        return false if !lineText.includes?("|")
        rows = self.escapedSplit(lineText.gsub(/^\||\|$/, ""))
        return false if (aligns.size != rows.size)
        return true  if silent

        token     = state.push("table_open", "table", 1)
        token.map = tableLines = [ startLine, 0 ]

        token     = state.push("thead_open", "thead", 1)
        token.map = [ startLine, startLine + 1 ]

        token     = state.push("tr_open", "tr", 1)
        token.map = [ startLine, startLine + 1 ]

        (0...rows.size).each do |i|
          token          = state.push("th_open", "th", 1)
          token.map      = [ startLine, startLine + 1 ]
          unless aligns[i].empty?
            token.attrs  = [ [ "style", "text-align:" + aligns[i] ] ]
          end

          token          = state.push("inline", "", 0)
          token.content  = rows[i].strip
          token.map      = [ startLine, startLine + 1 ]
          token.children = [] of Token

          token          = state.push("th_close", "th", -1)
        end

        token     = state.push("tr_close", "tr", -1)
        token     = state.push("thead_close", "thead", -1)

        token     = state.push("tbody_open", "tbody", 1)
        token.map = tbodyLines = [ startLine + 2, 0 ]

        nextLine = startLine + 2
        while nextLine < endLine
          break if (state.sCount[nextLine] < state.blkIndent)

          lineText = getLine(state, nextLine).strip
          break if !lineText.includes?("|")
          rows = self.escapedSplit(lineText.gsub(/^\||\|$/, ""))

          # set number of columns to number of columns in header row
          rows_length = aligns.size

          token = state.push("tr_open", "tr", 1)
          (0...rows_length).each do |i|
            token          = state.push("td_open", "td", 1)
            unless aligns[i].empty?
              token.attrs  = [ [ "style", "text-align:" + aligns[i] ] ]
            end

            token          = state.push("inline", "", 0)
            token.content  = rows[i] ? rows[i].strip : ""
            token.children = [] of Token

            token          = state.push("td_close", "td", -1)
          end
          token = state.push("tr_close", "tr", -1)
          nextLine += 1
        end
        token = state.push("tbody_close", "tbody", -1)
        token = state.push("table_close", "table", -1)

        tableLines[1] = tbodyLines[1] = nextLine
        state.line = nextLine
        return true
      end

    end
  end
end
