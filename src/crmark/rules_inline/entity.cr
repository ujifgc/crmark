# Process html entity - &#123;, &#xAF;, &quot;, ...
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Entity
      extend Common::Utils
      
      DIGITAL_RE = /^&#((?:x[a-f0-9]{1,8}|[0-9]{1,8}));/i
      NAMED_RE   = /^&([a-z][a-z0-9]{1,31});/i
      MAX_ENTITY_SIZE = 64


      #------------------------------------------------------------------------------
      def self.entity(state, silent)
        pos = state.pos
        max = state.posMax

        return false if state.src.charCodeAt(pos) != 0x26    # &

        html_size = [MAX_ENTITY_SIZE, state.src.size - pos].min

        if pos + 1 < max
          ch = state.src.charCodeAt(pos + 1)

          if ch == 0x23     # '#'
            if match = DIGITAL_RE.bytematch(state.src[pos, html_size])
              if !silent
                code = match[1][0].chr.downcase == 'x' ? String.new(match[1][1..-1]).to_i(16) : String.new(match[1]).to_i
                state.pending += isValidEntityCode(code) ? fromCodePoint(code) : fromCodePoint(0xFFFD)
              end
              state.pos += match[0].size
              return true
            end
          else
            if match = NAMED_RE.bytematch(state.src[pos, html_size])
              entity_name = String.new(match[1])
              if HTMLEntities::MAPPINGS[entity_name]?
                state.pending += HTMLEntities::MAPPINGS[entity_name] if !silent
                state.pos     += match[0].size
                return true
              end
            end
          end
        end

        state.pending += "&" if !silent
        state.pos += 1
        return true
      end

    end
  end
end
