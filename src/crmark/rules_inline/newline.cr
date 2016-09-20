# Proceess '\n'
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Newline

      #------------------------------------------------------------------------------
      def self.newline(state, silent)
        pos = state.pos
        return false if state.src.charCodeAt(pos) != 0x0A  # \n

        pmax  = state.pending.size - 1
        max   = state.posMax

        # '  \n' -> hardbreak
        # Lookup in pending chars is bad practice! Don't copy to other rules!
        # Pending string is stored in concat mode, indexed lookups will cause
        # convertion to flat mode.
        if !silent
          if pmax >= 0 && state.pending.charCodeAt(pmax) == 0x20
            if pmax >= 1 && state.pending.charCodeAt(pmax - 1) == 0x20
              state.pending = state.pending.sub(/ +$/, "")
              state.push("hardbreak", "br", 0)
            else
              state.pending = state.pending[0...-1]
              state.push("softbreak", "br", 0)
            end

          else
            state.push("softbreak", "br", 0)
          end
        end

        pos += 1

        # skip heading spaces for next line
        while pos < max && state.src.charCodeAt(pos) == 0x20
          pos += 1
        end

        state.pos = pos
        return true
      end

    end
  end
end
