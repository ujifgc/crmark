require "./rules_inline/*"

# internal
# class ParserInline
#
# Tokenizes paragraph content.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserInline
    
    property :ruler, :ruler2

    #------------------------------------------------------------------------------
    # Parser rules

    RULES = [
      { "text",            -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Text.text(state, silent) } },
      { "newline",         -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Newline.newline(state, silent) } },
      { "escape",          -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Escape.escape(state, silent) } },
      { "backticks",       -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Backticks.backtick(state, silent) } },
      { "strikethrough",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Strikethrough.tokenize(state, silent) } },
      { "emphasis",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Emphasis.tokenize(state, silent) } },
      { "link",            -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Link.link(state, silent) } },
      { "image",           -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Image.image(state, silent) } },
      { "autolink",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Autolink.autolink(state, silent) } },
      { "html_inline",     -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::HtmlInline.html_inline(state, silent) } },
      { "entity",          -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Entity.entity(state, silent) } },
    ]

    RULES2 = [
      { "balance_pairs",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::BalancePairs.link_pairs(state) } },
      { "strikethrough",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Strikethrough.postProcess(state, silent) } },
      { "emphasis",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::Emphasis.postProcess(state, silent) } },
      { "text_collapse",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesInline::TextCollapse.text_collapse(state) } },
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

      @ruler2 = Ruler.new

      RULES2.each do |rule|
        @ruler2.push(*rule)
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

      if cache[pos]?
        state.pos = cache[pos]
        return
      end

      # istanbul ignore else
      if state.level < maxNesting
        0.upto(len -1) do |i|
          if rules[i].call(state, 0, 0, true)
            cache[pos] = state.pos
            return
          end
        end
      end

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

      while state.pos < end_pos
        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.pos`
        # - update `state.tokens`
        # - return true

        ok = false
        if state.level < maxNesting
          0.upto(len - 1) do |i|
            ok = rules[i].call(state, 0, 0, false)
            break if ok
          end
        end

        if ok
          break if state.pos >= end_pos
          next
        end

        state.pending += state.src[state.pos].chr
        state.pos     += 1
      end

      unless state.pending.empty?
        state.pushPending
      end
    end

    # ParserInline.parse(str, md, env, outTokens)
    #
    # Process input string and push inline tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(str, md, env, outTokens)
      state = RulesInline::StateInline.new(str, md, env, outTokens)

      tokenize(state)

      rules = ruler2.getRules("")
      rules.each do |rule|
        rule.call(state, 0, 0, false)
      end
    end
  end
end
