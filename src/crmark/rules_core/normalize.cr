# Normalize input string
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Normalize

      NEWLINES_RE  = /\r[\n#{"\u0085"}]?|[#{"\u2424\u2028\u0085"}]/
      NULL_RE      = /#{"\u0000"}/


      #------------------------------------------------------------------------------
      def self.inline(state)
        false
      end
    end
  end
end