# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Emphasis
      extend MarkdownIt::Common::Utils
      
      def self.tokenize(state, silent)
        start = state.pos
        marker = state.src[start]

        return false if silent

        return false if marker != 0x5F && marker != 0x2A # _ ;

        scanned = state.scanDelims(state.pos, marker == 0x2A)

        i = 0
        while i < scanned.size
          token         = state.push(:text, "", 0);
          token.content = state.src[start, 1]

          state.delimiters.push(Delimiter.new(
            # Char code of the starting marker (number).
            #
            marker: marker,

            # Total length of these series of delimiters.
            #
            size: scanned.size,

            # An amount of characters before this one that's equivalent to
            # current one. In plain English: if this delimiter does not open
            # an emphasis, neither do previous `jump` characters.
            #
            # Used to skip sequences like "*****" in one step, for 1st asterisk
            # value will be 0, for 2nd it's 1 and so on.
            #
            jump:   i,

            # A position of the token this delimiter corresponds to.
            #
            token:  state.tokens.size - 1,

            # Token level.
            #
            level:  state.level,

            # If this delimiter is matched as a valid opener, `end` will be
            # equal to its position, otherwise it's `-1`.
            #
            end:    -1,

            # Boolean flags that determine if this delimiter could open or close
            # an emphasis.
            #
            open:   scanned.open,
            close:  scanned.close
          ))
          i += 1
        end

        state.pos += scanned.size

        true
      end

      def self.postProcess(state, silent)
        delimiters = state.delimiters
        max = delimiters.size

        i = max - 1
        while i >= 0
          startDelim = delimiters[i]

          if startDelim.marker != 0x5F && startDelim.marker != 0x2A # _ *
            i -= 1
            next
          end

          # Process only opening markers
          if startDelim.end == -1
            i -= 1
            next
          end

          endDelim = delimiters[startDelim.end]

          # If the next delimiter has the same marker and is adjacent to this one,
          # merge those into one strong delimiter.
          #
          # `<em><em>whatever</em></em>` -> `<strong>whatever</strong>`
          #
          isStrong = (i - 1 >= 0) &&
                     (delimiters[i - 1].end == startDelim.end + 1) &&
                     (delimiters[i - 1].token == startDelim.token - 1) &&
                     (delimiters[startDelim.end + 1].token == endDelim.token + 1) &&
                     delimiters[i - 1].marker == startDelim.marker

          ch = startDelim.marker.to_s

          token         = state.tokens[startDelim.token]
          token.type    = isStrong ? :strong_open : :em_open
          token.tag     = isStrong ? "strong" : "em"
          token.nesting = 1
          token.markup  = isStrong ? ch + ch : ch
          token.content = "".to_slice

          token         = state.tokens[endDelim.token]
          token.type    = isStrong ? :strong_close : :em_close
          token.tag     = isStrong ? "strong" : "em"
          token.nesting = -1
          token.markup  = isStrong ? ch + ch : ch
          token.content = "".to_slice

          if (isStrong)
            state.tokens[delimiters[i - 1].token].content = "".to_slice
            state.tokens[delimiters[startDelim.end + 1].token].content = "".to_slice
            i -= 1
          end
          i -= 1
        end
        true
      end

    end
  end
end
