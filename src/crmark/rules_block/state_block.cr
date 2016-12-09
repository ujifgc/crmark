# Parser state class
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class StateBlock < ParserState

      @pending : String

      #------------------------------------------------------------------------------
      def initialize(@src : Bytes, @md : Parser, @env, @tokens : Array(Token))
        @pos          = 0
        @posMax       = @src.size
        @level        = 0
        @pending      = ""
        @pendingLevel = 0
        @cache        = {} of Int32 => Int32     # Stores { start: end } pairs. Useful for backtrack !!!
                                                 # optimization of pairs parse (emphasis, strikes).
        @delimiters = [] of Delimiter;   # Emphasis-like delimiters
        @inlineMode = false

        @bMarks = [] of Int32 # line begin offsets for fast jumps
        @eMarks = [] of Int32 # line end offsets for fast jumps
        @tShift = [] of Int32 # offsets of the first non-space characters (tabs not expanded)
        @sCount = [] of Int32 # indents for each line (tabs expanded)

        # An amount of virtual spaces (tabs expanded) between beginning
        # of each line (bMarks) and real beginning of that line.
        #
        # It exists only as a hack because blockquotes override bMarks
        # losing information in the process.
        #
        # It's used only when expanding tabs, you can think about it as
        # an initial tab length, e.g. bsCount=21 applied to string `\t123`
        # means first tab should be expanded to 4-21%4 === 3 spaces.
        #
        @bsCount = [] of Int32

        # block parser variables
        @blkIndent  = 0       # required block content indent (for example, if we are in list)
        @line       = 0       # line index in src
        @lineMax    = 0       # lines count
        @tight      = false   # loose/tight mode for lists
        @ddIndent   = -1      # indent of the current dd block (-1 if there isn't any)
        @offset = 0

        # can be 'blockquote', 'list', 'root', 'paragraph' or 'reference'
        # used in lists to determine if they interrupt a paragraph
        @parentType = "root"

        @level = 0

        # renderer
        @result = ""

        # Create caches
        # Generate markers.
        s            = @src
        indent       = 0
        indent_found = false

        start = pos = indent = offset = 0
        len = s.size
        while pos < len
          ch = s.charCodeAt(pos)

          if !indent_found
            if ch == 0x20 || ch == 0x09
              indent += 1
              if ch == 0x09
                offset += 4 - offset % 4;
              else
                offset += 1
              end
              pos += 1
              next
            else
              indent_found = true
            end
          end

          if ch == 0x0A || pos == (len - 1)
            pos += 1 if ch != 0x0A
            @bMarks.push(start)
            @eMarks.push(pos)
            @tShift.push(indent)
            @sCount.push(offset)
            @bsCount.push(0)

            indent_found = false
            indent       = 0
            offset       = 0
            start        = pos + 1
          end
          pos += 1
        end

        # Push fake entry to simplify cache bounds checks
        @bMarks.push(s.size)
        @eMarks.push(s.size)
        @tShift.push(0)
        @sCount.push(0)
        @bsCount.push(0)

        @lineMax = @bMarks.size - 1 # don't count last fake line
      end

      # Push new token to "stream".
      #------------------------------------------------------------------------------
      def push(type : Symbol, tag, nesting)
        token       = Token.new(type, tag, nesting)
        token.block = true

        @level -= 1 if nesting < 0
        token.level = @level
        @level += 1 if nesting > 0

        @tokens.push(token)
        return token
      end

      #------------------------------------------------------------------------------
      def isEmpty(line)
        @bMarks[line] + @tShift[line] >= @eMarks[line]
      end

      #------------------------------------------------------------------------------
      def skipEmptyLines(from)
        while from < @lineMax
          break if (@bMarks[from] + @tShift[from] < @eMarks[from])
          from += 1
        end
        return from
      end

      # Skip spaces from given position.
      #------------------------------------------------------------------------------
      def skipSpaces(pos)
        max = @src.size
        while pos < max
          ch = @src.charCodeAt(pos)
          break unless ch == 0x20 || ch == 0x09 # space
          pos += 1
        end
        pos
      end

      # Skip spaces reverse from given position
      #------------------------------------------------------------------------------
      def skipSpacesBack(pos, min)
        return pos if pos <= min

        while pos > min
          ch = @src.charCodeAt(pos -= 1)
          return (pos + 1) unless ch == 0x20 || ch == 0x09
        end
        return pos
      end

      # Skip char codes from given position
      #------------------------------------------------------------------------------
      def skipChars(pos, code)
        max = @src.size
        while pos < max
          break if (@src.charCodeAt(pos) != code)
          pos += 1
        end
        return pos
      end

      # Skip char codes reverse from given position - 1
      #------------------------------------------------------------------------------
      def skipCharsBack(pos, code, min)
        return pos if pos <= min

        while (pos > min)
          return (pos + 1) if code != @src.charCodeAt(pos -= 1)
        end
        return pos
      end

      # cut lines range from source.
      #------------------------------------------------------------------------------
      def getLines(line_begin, line_end, indent, keepLastLF)
        line = line_begin

        return "".to_slice if line_begin >= line_end

        queue = Array(String).new(line_end - line_begin, "")

        i = 0
        while line < line_end
          lineIndent = 0
          lineStart = first = @bMarks[line]

          if line + 1 < line_end || keepLastLF
            # No need for bounds check because we have fake entry on tail.
            last = @eMarks[line] + 1
          else
            last = @eMarks[line]
          end

          while first < last && lineIndent < indent
            ch = @src.charCodeAt(first)
            if ch == 0x20 || ch == 0x09
              if ch == 0x09
                lineIndent += 4 - (lineIndent + @bsCount[line]) % 4
              else
                lineIndent += 1
              end
            elsif first - lineStart < @tShift[line]
              # patched tShift masked characters to look like spaces (blockquotes, list markers)
              lineIndent += 1
            else
              break
            end
            first += 1
          end

          last = @src.size if last > @src.size
          if lineIndent > indent
            # partially expanding tabs in code blocks, e.g '\t\tfoobar'
            # with indent=2 becomes '  \tfoobar'
            queue[i] = " "*(lineIndent - indent) + String.new(@src[first...last])
          else
            queue[i] = String.new(@src[first...last])
          end

          line += 1
          i    += 1
        end

        return queue.join("").to_slice # !!!
      end

    end
  end
end