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
      # First 2 params - rule name & source. Secondary array - list of rules, which can be terminated by this one.
      { "table",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Table.table(state, startLine, endLine, silent) },           [ "paragraph", "reference" ] },
      { "code",         -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Code.code(state, startLine, endLine, silent) },             [] of String },
      { "fence",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Fence.fence(state, startLine, endLine, silent) },           [ "paragraph", "reference", "blockquote", "list" ] },
      { "blockquote",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Blockquote.blockquote(state, startLine, endLine, silent) }, [ "paragraph", "reference", "list" ] },
      { "hr",           -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Hr.hr(state, startLine, endLine, silent) },                 [ "paragraph", "reference", "blockquote", "list" ] },
      { "list",         -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::List.list(state, startLine, endLine, silent) },             [ "paragraph", "reference", "blockquote" ] },
      { "reference",    -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Reference.reference(state, startLine, endLine, silent) },   [] of String },
      { "heading",      -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Heading.heading(state, startLine, endLine, silent) },       [ "paragraph", "reference", "blockquote" ] },
      { "lheading",     -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Lheading.lheading(state, startLine, endLine, silent) },     [] of String },
      { "html_block",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::HtmlBlock.html_block(state, startLine, endLine, silent) },  [ "paragraph", "reference", "blockquote" ] },
      { "paragraph",    -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesBlock::Paragraph.paragraph(state, startLine) },                    [] of String }
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

      while line < endLine
        state.line = line = state.skipEmptyLines(line)
        break if line >= endLine

        # Termination condition for nested calls.
        # Nested calls currently used for blockquotes & lists
        break if state.sCount[line] < state.blkIndent

        # If nesting level exceeded - skip tail to the end. That"s not ordinary
        # situation and we should not care about content.
        if state.level >= maxNesting
          state.line = endLine
          break
        end

        # Try all possible rules.
        # On success, rule should:
        #
        # - update `state.line`
        # - update `state.tokens`
        # - return true
        0.upto(len - 1) do |i|
          ok = rules[i].call(state, line, endLine, false)
          break if ok
        end

        # set state.tight if we had an empty line before current tag
        # i.e. latest empty line should not count
        state.tight = !hasEmptyLines

        # paragraph might "eat" one newline after it in nested lists
        if state.isEmpty(state.line - 1)
          hasEmptyLines = true
        end

        line = state.line
        if line < endLine && state.isEmpty(line)
          hasEmptyLines = true
          line += 1

          state.line = line
        end
      end
    end

    # ParserBlock.parse(src, md, env, outTokens)
    #
    # Process input string and push block tokens into `outTokens`
    #------------------------------------------------------------------------------
    def parse(src : Bytes, md, env, outTokens)
      state = RulesBlock::StateBlock.new(src, md, env, outTokens)

      tokenize(state, state.line, state.lineMax)
    end

  end
end
