# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Emphasis
      extend MarkdownIt::Common::Utils
      
      # parse sequence of emphasis markers,
      # "start" should point at a valid marker
      #------------------------------------------------------------------------------
      def self.scanDelims(state, start)
        pos            = start
        left_flanking  = true
        right_flanking = true
        max            = state.posMax
        marker         = state.src.charCodeAt(start)

        # treat beginning of the line as a whitespace
        lastChar = start > 0 ? state.src.charCodeAt(start - 1) : 0x20

        while (pos < max && state.src.charCodeAt(pos) == marker)
          pos += 1
        end

        count = pos - start

        # treat end of the line as a whitespace
        nextChar = pos < max ? state.src.charCodeAt(pos) : 0x20

        isLastPunctChar = isMdAsciiPunct(lastChar) || isPunctChar(lastChar.chr)
        isNextPunctChar = isMdAsciiPunct(nextChar) || isPunctChar(nextChar.chr)

        isLastWhiteSpace = isWhiteSpace(lastChar)
        isNextWhiteSpace = isWhiteSpace(nextChar)

        if (isNextWhiteSpace)
          left_flanking = false
        elsif (isNextPunctChar)
          if (!(isLastWhiteSpace || isLastPunctChar))
            left_flanking = false
          end
        end

        if (isLastWhiteSpace)
          right_flanking = false
        elsif (isLastPunctChar)
          if (!(isNextWhiteSpace || isNextPunctChar))
            right_flanking = false
          end
        end

        if (marker == 0x5F) # _
          # "_" inside a word can neither open nor close an emphasis
          can_open  = left_flanking  && (!right_flanking || isLastPunctChar)
          can_close = right_flanking && (!left_flanking  || isNextPunctChar)
        else
          can_open  = left_flanking
          can_close = right_flanking
        end

        return { can_open: can_open, can_close: can_close, delims: count }
      end

      #------------------------------------------------------------------------------
      def self.emphasis(state, silent)
        max    = state.posMax
        start  = state.pos
        marker = state.src.charCodeAt(start)

        return false if (marker != 0x5F && marker != 0x2A) #  _ *
        return false if (silent) # don't run any pairs in validation mode

        res = scanDelims(state, start)
        startCount = res[:delims]
        if (!res[:can_open])
          state.pos += startCount
          # Earlier we checked !silent, but this implementation does not need it
          state.pending += state.src[start...state.pos]
          return true
        end

        state.pos = start + startCount
        stack = [ startCount ]

        while (state.pos < max)
          if state.src.charCodeAt(state.pos) == marker
            res = scanDelims(state, state.pos)
            count = res[:delims]
            if (res[:can_close])
              oldCount = stack.pop()
              newCount = count

              while (oldCount != newCount)
                if (newCount < oldCount)
                  stack.push(oldCount - newCount)
                  break
                end

                # assert(newCount > oldCount)
                newCount -= oldCount

                break if (stack.size == 0)
                state.pos += oldCount
                oldCount = stack.pop()
              end

              if (stack.size == 0)
                startCount = oldCount
                found      = true
                break
              end
              state.pos += count
              next
            end

            stack.push(count) if (res[:can_open])
            state.pos += count
            next
          end

          state.md.inline.skipToken(state)
        end

        if (!found)
          # parser failed to find ending tag, so it's not valid emphasis
          state.pos = start
          return false
        end

        # found!
        state.posMax = state.pos
        state.pos    = start + startCount

        # Earlier we checked !silent, but this implementation does not need it

        # we have `startCount` starting and ending markers,
        # now trying to serialize them into tokens
        count = startCount
        while count > 1
          token        = state.push("strong_open", "strong", 1)
          token.markup = marker.chr.to_s + marker.chr.to_s
          count -= 2
        end
        if (count % 2 == 1)
          token        = state.push("em_open", "em", 1)
          token.markup = marker.chr.to_s
        end

        state.md.inline.tokenize(state)

        if (count % 2 == 1)
          token        = state.push("em_close", "em", -1)
          token.markup = marker.chr.to_s
        end
        count = startCount
        while count > 1
          token        = state.push("strong_close", "strong", -1)
          token.markup = marker.chr.to_s + marker.chr.to_s
          count -= 2
        end

        state.pos     = state.posMax + startCount
        state.posMax  = max
        return true
      end

    end
  end
end
