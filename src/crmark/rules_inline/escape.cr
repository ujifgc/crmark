# Proceess escaped chars and hardbreaks
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Escape

      ESCAPED = Array(Bool).new(255, false)

      "\\!\"#$%&\'()*+,./:;<=>?@[]^_`{|}~-".each_byte { |ch| ESCAPED[ch] = true }

      #------------------------------------------------------------------------------
      def self.escape(state, silent)
        pos = state.pos
        max = state.posMax

        return false if state.src.charCodeAt(pos) != 0x5C    # \

        pos += 1

        if pos < max
          ch = state.src.charCodeAt(pos)

          if ESCAPED[ch]?
            state.pending += state.src[pos].chr if !silent
            state.pos     += 2
            return true
          end

          if ch == 0x0A
            state.push("hardbreak", "br", 0) if !silent

            pos += 1
            # skip leading whitespaces from next line
            while pos < max
              ch = state.src.charCodeAt(pos)
              break if !ch.space_tab?
              pos += 1
            end

            state.pos = pos
            return true
          end
        end

        state.pending += "\\" if !silent
        state.pos += 1
        return true
      end

    end
  end
end
