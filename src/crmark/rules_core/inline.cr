module MarkdownIt
  module RulesCore
    class Inline

      #------------------------------------------------------------------------------
      def self.inline(state)
puts __FILE__+__LINE__.to_s
        tokens = state.tokens

puts __FILE__+__LINE__.to_s
        # Parse inlines
        0.upto(tokens.size - 1) do |i|
puts __FILE__+__LINE__.to_s
          tok = tokens[i]
          if tok.type == "inline"
puts __FILE__+__LINE__.to_s
            state.md.inline.parse(tok.content, state.md, state.env, tok.children)
          end
        end
puts __FILE__+__LINE__.to_s
        true
      end

    end
  end
end