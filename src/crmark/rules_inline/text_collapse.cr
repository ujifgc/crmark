# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class TextCollapse
      extend MarkdownIt::Common::Utils

      def self.text_collapse(state)
        level = 0
        tokens = state.tokens
        max = tokens.size

        curr = last = 0
        while curr < max
          # re-calculate levels
          level += tokens[curr].nesting
          tokens[curr].level = level

          if tokens[curr].type == "text" && (curr + 1 < max) && tokens[curr + 1].type == "text"

            # collapse two adjacent text nodes
            tokens[curr + 1].content = tokens[curr].content + tokens[curr + 1].content
          else
            if (curr != last) 
              tokens[last] = tokens[curr]
            end

            last += 1
          end
          curr += 1
        end

        if curr != last
          tokens.delete_at(last..-1)
        end

        true
      end

    end
  end
end
