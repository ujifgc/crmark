require "./rules_block/*"

# internal
# class ParserBlock
#
# Block-level tokenizer.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserBlock

    property :ruler
    
    RULES = [
      # First 2 params - rule name & source. Secondary array - list of rules,
      # which can be terminated by this one.
      { "code",         -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Code.code(state, startLine, endLine, silent) }, [] of String },
      { "fence",        -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Fence.fence(state, startLine, endLine, silent) },      [ "paragraph", "reference", "blockquote", "list" ] },
      { "blockquote",   -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Blockquote.blockquote(state, startLine, endLine, silent) }, [ "paragraph", "reference", "list" ] },
      { "hr",           -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Hr.hr(state, startLine, endLine, silent) },         [ "paragraph", "reference", "blockquote", "list" ] },
      { "list",         -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::List.list(state, startLine, endLine, silent) },       [ "paragraph", "reference", "blockquote" ] },
      { "reference",    -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Reference.reference(state, startLine, endLine, silent) }, [] of String },
      { "heading",      -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Heading.heading(state, startLine, endLine, silent) },    [ "paragraph", "reference", "blockquote" ] },
      { "lheading",     -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Lheading.lheading(state, startLine, endLine, silent) }, [] of String },
      { "html_block",   -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::HtmlBlock.html_block(state, startLine, endLine, silent) }, [ "paragraph", "reference", "blockquote" ] },
      { "table",        -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Table.table(state, startLine, endLine, silent) },      [ "paragraph", "reference" ] },
      { "paragraph",    -> (state : RuleState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Paragraph.paragraph(state, startLine) }, [] of String }
    ]
       

    # new ParserBlock()
    #------------------------------------------------------------------------------
    def initialize
      # ParserBlock#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of block rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(*rule)
      end
    end


    # Generate tokens for input range
    #------------------------------------------------------------------------------
    def tokenize(state, startLine, endLine, ignored = false)
      rules         = @ruler.getRules("")
      len           = rules.size
      line          = startLine
      hasEmptyLines = false
      maxNesting    = state.md.options[:maxNesting]
puts __FILE__+__LINE__.to_s
      while line < endLine
puts __FILE__+__LINE__.to_s
        state.line = line = state.skipEmptyLines(line)
puts state.line
        break if line >= endLine

        # Termination condition for nested calls.
        # Nested calls currently used for blockquotes & lists
        break if state.tShift[line] < state.blkIndent

        # If nesting level exceeded - skip tail to the end. That"s not ordinary
        # situation and we should not care about content.
        if state.level >= maxNesting
          state.line = endLine
          break
        end

puts state.line
        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.line`
        # - update `state.tokens`
        # - return true
puts "GO UPTP"
        0.upto(len - 1) do |i|
          ok = rules[i].call(state, line, endLine, false)
          break if ok
        end
puts "UPTP"
puts state.line

        # set state.tight iff we had an empty line before current tag
        # i.e. latest empty line should not count
        state.tight = !hasEmptyLines

        # paragraph might "eat" one newline after it in nested lists
        if state.isEmpty(state.line - 1)
          hasEmptyLines = true
        end

        line = state.line
puts line
puts endLine
        if line < endLine && state.isEmpty(line)
          hasEmptyLines = true
          line += 1

          # two empty lines should stop the parser in list mode
          break if line < endLine && state.parentType == "list" && state.isEmpty(line)
          state.line = line
        end
      end
    end

    # ParserBlock.parse(src, md, env, outTokens)
    #
    # Process input string and push block tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(src, md, env, outTokens)
puts __FILE__+__LINE__.to_s
      state = RulesBlock::StateBlock.new(src, md, env, outTokens)
puts __FILE__+__LINE__.to_s

      z=tokenize(state, state.line, state.lineMax)
puts __FILE__+__LINE__.to_s
      z
    end

  end
end