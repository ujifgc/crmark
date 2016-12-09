# class Renderer
#
# Generates HTML from parsed token stream. Each instance has independent
# copy of rules. Those can be rewritten with ease. Also, you can add new
# rules if you create plugin and adds new token types.
#------------------------------------------------------------------------------
module MarkdownIt
  class Renderer
    include Common::Utils

    @tokens : Array(Token)

    # new Renderer()
    #
    # Creates new [[Renderer]] instance and fill [[Renderer#rules]] with defaults.
    #------------------------------------------------------------------------------
    def initialize(@tokens, @options = Presets::Default::OPTIONS)
    end

    # Renderer.render(tokens, options) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    #
    # Takes token stream and generates HTML. Probably, you will never need to call
    # this method directly.
    #------------------------------------------------------------------------------
    def render
      String.build do |io|
        @tokens.size.times do |i|
          type = @tokens[i].type

          if type == :inline
            renderInline(io, @tokens[i].children, @options)
          else
            renderRule(io, type, @tokens, i, @options)
          end
        end
      end
    end

    # Renderer.renderAttrs(token) -> String
    #
    # Render token attributes to string.
    #------------------------------------------------------------------------------
    def renderAttrs(token)
      return "" if !token.attrs

      result = ""
      token.attrs.size.times do |i|
        result += " " + escapeHtml(token.attrs[i][0].to_slice) + "=\"" + escapeHtml(token.attrs[i][1].to_s.to_slice) + "\""
      end

      return result
    end


    # Renderer.renderToken(tokens, idx, options) -> String
    # - tokens (Array): list of tokens
    # - idx (Numbed): token index to render
    # - options (Object): params of parser instance
    #
    # Default token renderer. Can be overriden by custom function
    # in [[Renderer#rules]].
    #------------------------------------------------------------------------------
    def renderToken(io, tokens, idx, options)
      needLf = false
      token  = tokens[idx]

      # Tight list paragraphs
      return if token.hidden

      # Insert a newline between hidden paragraph and subsequent opening
      # block-level tag.
      #
      # For example, here we should insert a newline before blockquote:
      #  - a
      #    >
      #
      if token.block && token.nesting != -1 && idx && tokens[idx - 1].hidden
        io << "\n"
      end

      # Add token name, e.g. `<img`
      io << (token.nesting == -1 ? "</" : "<") << token.tag

      # Encode attributes, e.g. `<img src="foo"`
      io << renderAttrs(token)

      # Add a slash for self-closing tags, e.g. `<img src="foo" /`
      if token.nesting == 0 && options[:xhtmlOut]
        io << " /"
      end

      # Check if we need to add a newline after this tag
      if token.block
        needLf = true

        if token.nesting == 1
          if idx + 1 < tokens.size
            nextToken = tokens[idx + 1]

            if nextToken.type == :inline || nextToken.hidden
              # Block-level tag containing an inline tag.
              #
              needLf = false
            elsif nextToken.tag == token.tag && nextToken.tag == "blockquote"
              # blockquote wants \n inside
            elsif nextToken.nesting == -1 && nextToken.tag == token.tag
              # Opening tag + closing tag of the same type. E.g. `<li></li>`.
              #
              needLf = false
            end
          end
        end
      end

      io << (needLf ? ">\n" : ">")
    end


    # Renderer.renderInline(tokens, options) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    #
    # The same as [[Renderer.render]], but for single token of `inline` type.
    #------------------------------------------------------------------------------
    def renderInline(io, tokens, options)
      tokens.size.times do |i|
        renderRule(io, tokens[i].type, tokens, i, options)
      end
    end


    # internal
    # Renderer.renderInlineAsText(tokens, options) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    #
    # Special kludge for image `alt` attributes to conform CommonMark spec.
    # Don't try to use it! Spec requires to show `alt` content with stripped markup,
    # instead of simple escaping.
    #------------------------------------------------------------------------------
    def renderInlineAsText(io, tokens, options)
      tokens.size.times do |i|
        if tokens[i].type == :text
          io.write tokens[i].content
        elsif tokens[i].type == :image
          renderInlineAsText(io, tokens[i].children, options)
        end
      end
    end

    # Default Rules
    #------------------------------------------------------------------------------
    def code_inline(io, token)
      io << "<code>" << escapeHtml(token.content) << "</code>"
    end

    #------------------------------------------------------------------------------
    def code_block(io, token)
      io << "<pre><code>" << escapeHtml(token.content) << "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def fence(io, token, options)
      langName  = ""

      if !token.info.empty?
        langName = unescapeAll(token.info).strip.split(/\s+/)[0]
        token.attrPush([ "class", options[:langPrefix] + langName ]) unless langName.empty?
      end

      io << "<pre><code" << renderAttrs(token) << ">" << escapeHtml(token.content) << "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def image(io, tokens, idx, options)
      token = tokens[idx]

      # "alt" attr MUST be set, even if empty. Because it's mandatory and
      # should be placed on proper position for tests.
      #
      # Replace content with actual value

      alt_io = IO::Memory.new
      renderInlineAsText(alt_io, token.children, options)
      token.attrs[token.attrIndex("alt")][1] = alt_io.to_s

      renderToken(io, tokens, idx, options)
    end

    #------------------------------------------------------------------------------
    def hardbreak(io, options)
      io << (options[:xhtmlOut] ? "<br />\n" : "<br>\n")
    end

    def softbreak(io, options)
      io << (options[:breaks] ? (options[:xhtmlOut] ? "<br />\n" : "<br>\n") : "\n")
    end

    #------------------------------------------------------------------------------
    def text(io, token)
      io << escapeHtml(token.content)
    end

    #------------------------------------------------------------------------------
    def html_block(io, token)
      io.write token.content
    end

    def html_inline(io, token)
      io.write token.content
    end

    def renderRule(io, type, tokens, i, options)
      case type
      when :code_inline
        code_inline(io, tokens[i])
      when :code_block
        code_block(io, tokens[i])
      when :fence
        fence(io, tokens[i], options)
      when :image
        image(io, tokens, i, options)
      when :hardbreak
        hardbreak(io, options)
      when :softbreak
        softbreak(io, options)
      when :text
        text(io, tokens[i])
      when :html_block
        html_block(io, tokens[i])
      when :html_inline
        html_inline(io, tokens[i])
      else
        renderToken(io, tokens, i, options)
      end
    end
  end
end
