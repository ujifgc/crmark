module MarkdownIt
  module RulesCore
    class Block

      #------------------------------------------------------------------------------
      def self.block(state)
puts __FILE__+__LINE__.to_s
        if state.inlineMode
puts __FILE__+__LINE__.to_s
          token          = Token.new("inline", "", 0)
          token.content  = state.src
          token.map      = [ 0, 1 ]
          token.children = [] of Token
          state.tokens.push(token)
        else
puts __FILE__+__LINE__.to_s
          state.md.block.parse(state.src, state.md, state.env, state.tokens)
        end
        true
      end

    end
  end
end
