# ~~strike through~~
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Strikethrough
      extend Common::Utils
      
      def self.tokenize(state, silent)
        start = state.pos
        marker = state.src.charCodeAt(start)

        return false if silent

        return false if marker != 0x7E # ~

        scanned = state.scanDelims(state.pos, true)
        len = scanned.size
        ch = marker.chr.to_s

        return false if len < 2

        if len % 2 != 0
          token         = state.push("text", "", 0)
          token.content = ch
          len -= 1
        end

        i = 0
        while i < len
          token         = state.push("text", "", 0)
          token.content = ch + ch

          state.delimiters.push(Delimiter.new(
            marker: marker,
            jump:   i,
            token:  state.tokens.size - 1,
            level:  state.level,
            end:    -1,
            open:   scanned.open,
            close:  scanned.close
          ))
          i += 2
        end

        state.pos += scanned.size

        true
      end

      def self.postProcess(state, silent)
        loneMarkers = [] of Int32
        delimiters = state.delimiters
        max = delimiters.size

        i = 0
        while i < max
          startDelim = delimiters[i]

          if startDelim.marker != 0x7E # ~
            i += 1
            next
          end

          if startDelim.end == -1
            i += 1
            next
          end

          endDelim = delimiters[startDelim.end]

          token         = state.tokens[startDelim.token]
          token.type    = "s_open"
          token.tag     = "s"
          token.nesting = 1
          token.markup  = "~~"
          token.content = ""

          token         = state.tokens[endDelim.token]
          token.type    = "s_close"
          token.tag     = "s"
          token.nesting = -1
          token.markup  = "~~"
          token.content = ""

          if (state.tokens[endDelim.token - 1].type == "text" &&
              state.tokens[endDelim.token - 1].content == "~")

            loneMarkers.push(endDelim.token - 1)
          end
          i += 1
        end

        # If a marker sequence has an odd number of characters, it"s splitted
        # like this: `~~~~~` -> `~` + `~~` + `~~`, leaving one marker at the
        # start of the sequence.
        #
        # So, we have to move all those markers after subsequent s_close tags.
        #
        while loneMarkers.size > 0
          i = loneMarkers.pop
          j = i + 1

          while (j < state.tokens.size && state.tokens[j].type == "s_close")
            j += 1
          end

          j -= 1

          if i != j
            token = state.tokens[j]
            state.tokens[j] = state.tokens[i]
            state.tokens[i] = token
          end
        end

        true
      end
    end
  end
end
