module MarkdownIt
  module RulesCore
    class Block

      #------------------------------------------------------------------------------
      def self.block(state)
        if state.inlineMode
          token          = Token.new(:inline, "", 0)
          token.content  = state.src
          token.map      = [ 0, 1 ]
          token.children = [] of Token
          state.tokens.push(token)
        else
          state.md.block.parse(state.src, state.md, state.env, state.tokens)
        end
        true
      end

    end
  end
end
