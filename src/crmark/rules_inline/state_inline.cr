# Inline parser state
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class StateInline < ParserState
      include Common::Utils

      # Flush pending text
      #------------------------------------------------------------------------------
      def pushPending
        token         = Token.new("text", "", 0)
        token.content = @pending
        token.level   = @pendingLevel
        @tokens.push(token)
        @pending      = ""
        return token
      end

      # Push new token to "stream".
      # If pending text exists - flush it as text token
      #------------------------------------------------------------------------------
      def push(type, tag, nesting)
        pushPending unless @pending.empty?

        token       = Token.new(type, tag, nesting);
        @level     -= 1 if nesting < 0
        token.level = @level
        @level     += 1 if nesting > 0

        @pendingLevel = @level
        @tokens.push(token)
        return token
      end

      def scanDelims(start, canSplitWord)
        pos = start
        left_flanking = true
        right_flanking = true
        max = @posMax
        marker = @src.charCodeAt(start)

        # treat beginning of the line as a whitespace
        lastChar = start > 0 ? @src.charCodeAt(start - 1) : 0x20

        while pos < max && @src.charCodeAt(pos) == marker
          pos += 1
        end

        count = pos - start

        # treat end of the line as a whitespace
        nextChar = pos < max ? @src.charCodeAt(pos) : 0x20

        isLastPunctChar = isMdAsciiPunct(lastChar) || isPunctChar(lastChar.to_s)
        isNextPunctChar = isMdAsciiPunct(nextChar) || isPunctChar(nextChar.to_s)

        isLastWhiteSpace = isWhiteSpace(lastChar)
        isNextWhiteSpace = isWhiteSpace(nextChar)

        if isNextWhiteSpace
          left_flanking = false
        elsif isNextPunctChar
          if !(isLastWhiteSpace || isLastPunctChar)
            left_flanking = false
          end
        end

        if isLastWhiteSpace
          right_flanking = false
        elsif isLastPunctChar
          if !(isNextWhiteSpace || isNextPunctChar)
            right_flanking = false
          end
        end

        if !canSplitWord
          can_open  = left_flanking  && (!right_flanking || isLastPunctChar)
          can_close = right_flanking && (!left_flanking  || isNextPunctChar)
        else
          can_open  = left_flanking
          can_close = right_flanking
        end

        Delimiter.new(
          open:  can_open,
          close: can_close,
          size:  count
        )
      end
    end
  end
end