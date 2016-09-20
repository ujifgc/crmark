module MarkdownIt
  class RuleState
    property :src, :md, :env, :tokens

    #block
    property :bMarks, :eMarks, :tShift
    property :blkIndent, :line, :lineMax, :tight, :parentType, :ddIndent
    property :level, :result
      
    #inline
    property :pos, :posMax, :level
    property :pending, :pendingLevel, :cache

    #core
    property :inlineMode

    @posMax : Int32

    def initialize(@src : String, @md : Parser, @env : String, @tokens = [] of Token)
      @pos          = 0
      @posMax       = @src.size
      @level        = 0
      @pending      = ""
      @pendingLevel = 0
      @cache        = {} of Int32 => Int32     # Stores { start: end } pairs. Useful for backtrack !!!
                                               # optimization of pairs parse (emphasis, strikes).
      @bMarks = [] of Int32 # line begin offsets for fast jumps
      @eMarks = [] of Int32 # line end offsets for fast jumps
      @tShift = [] of Int32 # indent for each line

      # block parser variables
      @blkIndent  = 0       # required block content indent (for example, if we are in list)
      @line       = 0       # line index in src
      @lineMax    = 0       # lines count
      @tight      = false   # loose/tight mode for lists
      @parentType = "root"  # if `list`, block parser stops on two newlines
      @ddIndent   = -1      # indent of the current dd block (-1 if there isn't any)

      @inlineMode = false
    end

    def isEmpty(line)
      raise "not implemented"
    end

    def skipChars(pos, code)
      raise "not implemented"
    end

    def skipCharsBack(pos, code, min)
      raise "not implemented"
    end

    def skipSpaces(pos)
      raise "not implemented"
    end

    def skipEmptyLines(from)
      raise "not implemented"
    end

    def getLines(line_begin, line_end, indent, keepLastLF)
      raise "not implemented"
    end

    def pushPending
      raise "not implemented"
    end

    def push(type, tag, nesting)
      raise "not implemented"
    end
  end
end
