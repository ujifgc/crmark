# Process *this* and _that_
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class BalancePairs
      extend MarkdownIt::Common::Utils

      def self.link_pairs(state)
        delimiters = state.delimiters
        max = delimiters.size

        i = 0
        while i < max
          lastDelim = delimiters[i]

          unless lastDelim.close
            i += 1
            next 
          end

          j = i - lastDelim.jump - 1

          while j >= 0
            currDelim = delimiters[j]

            if currDelim.open &&
               currDelim.marker == lastDelim.marker &&
               currDelim.end < 0 &&
               currDelim.level == lastDelim.level

              odd_match = (currDelim.close || lastDelim.open) &&
                          (currDelim.size > 0) && (lastDelim.size > 0) &&
                          ((currDelim.size + lastDelim.size) % 3 == 0)
              if !odd_match
                lastDelim.jump = i - j
                lastDelim.open = false
                currDelim.end  = i
                currDelim.jump = 0
                break
              end
            end

            j -= currDelim.jump + 1
          end
          i += 1
        end

        true
      end

    end
  end
end
