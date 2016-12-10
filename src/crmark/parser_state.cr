module MarkdownIt
  alias LinkReference = NamedTuple(title: String, href: String)
  alias StateEnv = NamedTuple(references: Hash(String, LinkReference))
  class Delimiter
    property :marker, :size, :jump, :token, :level, :end, :open, :close

    def initialize(
      @marker = 0x00_u8,
      @size = 0,
      @jump = 0,
      @token = 0,
      @level = 0,
      @end = 0,
      @open = false,
      @close = false
    )
    end
  end

  class ParserState
    property :src, :md, :env, :tokens

    #block
    property :bMarks, :eMarks, :tShift, :sCount, :bsCount
    property :blkIndent, :line, :lineMax, :tight, :parentType, :ddIndent
    property :level, :result

    #inline
    property :pos, :posMax, :level
    property :pending, :pendingLevel, :cache
    property :delimiters

    #core
    property :inlineMode

    @posMax : Int32
    @pending : IO::Memory

    def initialize(@src : Bytes, @md : Parser, @env : StateEnv, @tokens = [] of Token)
      @pos          = 0
      @posMax       = @src.size
      @level        = 0
      @pending      = IO::Memory.new
      @pendingLevel = 0
      @cache        = {} of Int32 => Int32     # Stores { start: end } pairs. Useful for backtrack !!!
                                               # optimization of pairs parse (emphasis, strikes).

      @delimiters = [] of Delimiter;   # Emphasis-like delimiters

      @bMarks = [] of Int32 # line begin offsets for fast jumps
      @eMarks = [] of Int32 # line end offsets for fast jumps
      @tShift = [] of Int32 # 
      @sCount = [] of Int32 # 
      @bsCount = [] of Int32 # 

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

    def skipSpacesBack(pos, min)
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

    def scanDelims(start, canSplitWords)
      raise "not implemented"
    end
  end
end
