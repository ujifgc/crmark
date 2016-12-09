# Token class
#------------------------------------------------------------------------------
module MarkdownIt
  class Token

    property :type, :tag, :attrs, :map, :nesting, :level, :children
    property :content, :markup, :info, :meta, :block, :hidden

    @markup : String
    @content : Bytes

    # new Token(type, tag, nesting)
    #
    # Create new token and fill passed properties.
    #------------------------------------------------------------------------------
    def initialize(type : String, tag : String, nesting : Int32)
      #  * Token#type -> String
      #  *
      #  * Type of the token (string, e.g. "paragraph_open")
      @type     = type

       # * Token#tag -> String
       # *
       # * html tag name, e.g. "p"
      @tag      = tag

       # * Token#attrs -> Array
       # *
       # * Html attributes. Format: `[ [ name1, value1 ], [ name2, value2 ] ]`
      @attrs    = Array(Array(String)).new

       # * Token#map -> Array
       # *
       # * Source map info. Format: `[ line_begin, line_end ]`
      @map      = Array(Int32).new

       # * Token#nesting -> Number
       # *
       # * Level change (number in {-1, 0, 1} set), where:
       # *
       # * -  `1` means the tag is opening
       # * -  `0` means the tag is self-closing
       # * - `-1` means the tag is closing
      @nesting  = nesting

       # * Token#level -> Number
       # *
       # * nesting level, the same as `state.level`
      @level    = 0

       # * Token#children -> Array
       # *
       # * An array of child nodes (inline and img tokens)
      @children = Array(Token).new

       # * Token#content -> String
       # *
       # * In a case of self-closing tag (code, html, fence, etc.),
       # * it has contents of this tag.
      @content = Bytes.empty

       # * Token#markup -> String
       # *
       # * '*' or '_' for emphasis, fence string for fence, etc.
      @markup   = ""

       # * Token#info -> String
       # *
       # * fence infostring
      @info     = ""

       # * Token#meta -> Object
       # *
       # * A place for plugins to store an arbitrary data
      @meta     = ""

       # * Token#block -> Boolean
       # *
       # * True for block-level tokens, false for inline tokens.
       # * Used in renderer to calculate line breaks
      @block    = false

       # * Token#hidden -> Boolean
       # *
       # * If it's true, ignore this element when rendering. Used for tight lists
       # * to hide paragraphs.
      @hidden   = false
    end


    # * Token.attrIndex(name) -> Number
    # *
    # * Search attribute index by name.
    #------------------------------------------------------------------------------
    def attrIndex(name)
      return -1 if !@attrs

      attrs = @attrs

      attrs.each_with_index do |attr_, index|
        return index if attr_[0] == name
      end
      return -1
    end

    # * Token.attrPush(attrData)
    # *
    # * Add `[ name, value ]` attribute to list. Init attrs if necessary
    #------------------------------------------------------------------------------
    def attrPush(attrData)
      if @attrs
        @attrs.push(attrData)
      else
        @attrs = [ attrData ]
      end
    end
    
    #------------------------------------------------------------------------------
    def to_json
      {
        type: @type,
        tag: @tag,
        attrs: @attrs,
        map: @map,
        nesting: @nesting,
        level: @level,
        children: @children.nil? ? nil : @children.each {|t| t.to_json},
        content: @content,
        markup: @markup,
        info: @info,
        meta: @meta,
        block: @block,
        hidden: @hidden
      }
    end
  end
end
