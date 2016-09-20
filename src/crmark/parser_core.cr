require "./rules_core/*"

# internal
# class Core
#
# Top-level rules executor. Glues block/inline parsers and does intermediate
# transformations.
#------------------------------------------------------------------------------
module MarkdownIt
  class ParserCore

    property :ruler
    
    RULES = [
      { "normalize",      -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Normalize.inline(state) }         },
      { "block",          -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Block.block(state) }              },
      { "inline",         -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Inline.inline(state) }            },
#     { "linkify",        -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Linkify.linkify(state) }          },
      { "replacements",   -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Replacements.replace(state) }     },
#     { "smartquotes",    -> (state : ParserState, startLine : Int32, endLine : Int32, silent : Bool) { RulesCore::Smartquotes.smartquotes(state) }  },
    ]


    # new Core()
    #------------------------------------------------------------------------------
    def initialize
      # Core#ruler -> Ruler
      #
      # [[Ruler]] instance. Keep configuration of core rules.
      @ruler = Ruler.new

      RULES.each do |rule|
        @ruler.push(*rule)
      end
    end

    # Core.process(state)
    #
    # Executes core chain rules.
    #------------------------------------------------------------------------------
    def process(state)
      rules = @ruler.getRules("")
      rules.each do |rule|
        rule.call(state, 0, 0, true)
      end
    end
  end
end