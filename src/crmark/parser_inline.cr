require "./rules_inline/*"

# internal
# class ParserInline
#
# Tokenizes paragraph content.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserInline
    
    property :ruler

    #------------------------------------------------------------------------------
    # Parser rules

    RULES = [
      { "text",            -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Text.text(state, silent) } },
      { "newline",         -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Newline.newline(state, silent) } },
      { "escape",          -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Escape.escape(state, silent) } },
      { "backticks",       -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Backticks.backtick(state, silent) } },
      { "strikethrough",   -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Strikethrough.strikethrough(state, silent) } },
      { "emphasis",        -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Emphasis.emphasis(state, silent) } },
      { "link",            -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Link.link(state, silent) } },
      { "image",           -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Image.image(state, silent) } },
      { "autolink",        -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Autolink.autolink(state, silent) } },
      { "html_inline",     -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::HtmlInline.html_inline(state, silent) } },
      { "entity",          -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Entity.entity(state, silent) } },
    ]

    #------------------------------------------------------------------------------
    def initialize
      # ParserInline#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of inline rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(*rule)
      end
    end

    # Skip single token by running all rules in validation mode;
    # returns `true` if any rule reported success
    #------------------------------------------------------------------------------
    def skipToken(state)
      pos        = state.pos
      rules      = @ruler.getRules("")
      len        = rules.size
      maxNesting = state.md.options[:maxNesting]
      cache      = state.cache

puts __FILE__+__LINE__.to_s

      if cache[pos]?
        state.pos = cache[pos]
        return
      end

puts __FILE__+__LINE__.to_s

      # istanbul ignore else
      if state.level < maxNesting
        0.upto(len -1) do |i|
          if rules[i].call(state, 0, 0, true)
            cache[pos] = state.pos
            return
          end
        end
      end

puts __FILE__+__LINE__.to_s

      state.pos += 1
      cache[pos] = state.pos
    end


    # Generate tokens for input range
    #------------------------------------------------------------------------------
    def tokenize(state)
      rules      = @ruler.getRules("")
      len        = rules.size
      end_pos    = state.posMax
      maxNesting = state.md.options[:maxNesting]

puts state.src
puts __FILE__+__LINE__.to_s
      while state.pos < end_pos
        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.pos`
        # - update `state.tokens`
        # - return true

puts __FILE__+__LINE__.to_s
        ok = false
        if state.level < maxNesting
puts len
          0.upto(len - 1) do |i|
puts __FILE__+__LINE__.to_s
puts i
            ok = rules[i].call(state, 0, 0, false)
puts __FILE__+__LINE__.to_s
            break if ok
          end
        end
puts __FILE__+__LINE__.to_s

        if ok
          break if state.pos >= end_pos
          next
        end

        state.pending += state.src[state.pos]
        state.pos     += 1
      end
puts __FILE__+__LINE__.to_s

      unless state.pending.empty?
        state.pushPending
      end
    end

    # ParserInline.parse(str, md, env, outTokens)
    #
    # Process input string and push inline tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(str, md, env, outTokens)
puts __FILE__+__LINE__.to_s
      state = RulesInline::StateInline.new(str, md, env, outTokens)
puts __FILE__+__LINE__.to_s

      tokenize(state)
    end
  end
end