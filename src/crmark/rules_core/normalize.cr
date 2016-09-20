# Normalize input string
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Normalize

      TABS_SCAN_RE = /[\n\t]/
      NEWLINES_RE  = /\r[\n#{"\u0085"}]?|[#{"\u2424\u2028\u0085"}]/
      NULL_RE      = /#{"\u0000"}/


      #------------------------------------------------------------------------------
      def self.inline(state)
puts __FILE__+__LINE__.to_s
        # Normalize newlines
        str = state.src.gsub(NEWLINES_RE, "\n")

        # Replace NULL characters
        str = str.gsub(NULL_RE, "\uFFFD")

        state.src = str
        true
      end
    end
  end
end