# Proceess '\n'
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Newline

      #------------------------------------------------------------------------------
      def self.newline(state, silent)
        pos = state.pos
        return false if state.src[pos] != 0x0A  # \n

        pmax  = state.pending.size - 1
        max   = state.posMax

        # '  \n' -> hardbreak
        # Lookup in pending chars is bad practice! Don't copy to other rules!
        # Pending string is stored in concat mode, indexed lookups will cause
        # convertion to flat mode.
        if !silent
          if pmax >= 0 && state.pending.peek(pmax) == 0x20_u8
            if pmax >= 1 && state.pending.peek(pmax - 1) == 0x20_u8
              state.pending.chomp(0x20_u8)
              state.push(:hardbreak, "br", 0)
            else
              state.pending.chomp(0x20_u8)
              state.push(:softbreak, "br", 0)
            end
          else
            state.push(:softbreak, "br", 0)
          end
        end

        pos += 1

        # skip heading spaces for next line
        while pos < max && state.src[pos] == 0x20
          pos += 1
        end

        state.pos = pos
        return true
      end

    end
  end
end
