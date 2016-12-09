module MarkdownIt
  module RulesCore
    class Inline

      #------------------------------------------------------------------------------
      def self.inline(state)
        tokens = state.tokens

        # Parse inlines
        0.upto(tokens.size - 1) do |i|
          tok = tokens[i]
          if tok.type == :inline
            state.md.inline.parse(tok.content, state.md, state.env, tok.children)
          end
        end
        true
      end

    end
  end
end