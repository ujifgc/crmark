# class Renderer
#
# Generates HTML from parsed token stream. Each instance has independent
# copy of rules. Those can be rewritten with ease. Also, you can add new
# rules if you create plugin and adds new token types.
#------------------------------------------------------------------------------
module MarkdownIt
  class Renderer
    include MarkdownIt::Common::Utils
    extend  MarkdownIt::Common::Utils

    property :rules
    
    # Default Rules
    #------------------------------------------------------------------------------
    def self.code_inline(tokens, idx)
      return "<code>" + escapeHtml(String.new tokens[idx].content) + "</code>"
    end

    #------------------------------------------------------------------------------
    def self.code_block(tokens, idx)
      return "<pre><code>" + escapeHtml(String.new tokens[idx].content) + "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def self.fence(tokens, idx, options, env, renderer)
      token     = tokens[idx]
      langName  = ""

      if !token.info.empty?
        langName = unescapeAll(token.info.strip.split(/\s+/)[0])
        token.attrPush([ "class", options[:langPrefix] + langName ])
      end

#      if options[:highlight]!!!
#        highlighted = options[:highlight].call(token.content, langName) || escapeHtml(token.content)
#      else
        highlighted = escapeHtml(String.new token.content)
#      end

      return  "<pre><code" + renderer.renderAttrs(token) + ">" + highlighted + "</code></pre>\n"
    end

    #------------------------------------------------------------------------------
    def self.image(tokens, idx, options, env, renderer)
      token = tokens[idx]

      # "alt" attr MUST be set, even if empty. Because it's mandatory and
      # should be placed on proper position for tests.
      #
      # Replace content with actual value

      token.attrs[token.attrIndex("alt")][1] = renderer.renderInlineAsText(token.children, options, env)

      return renderer.renderToken(tokens, idx, options);
    end

    #------------------------------------------------------------------------------
    def self.hardbreak(tokens, idx, options)
      return options[:xhtmlOut] ? "<br />\n" : "<br>\n"
    end
    def self.softbreak(tokens, idx, options)
      return options[:breaks] ? (options[:xhtmlOut] ? "<br />\n" : "<br>\n") : "\n"
    end

    #------------------------------------------------------------------------------
    def self.text(tokens, idx)
      return escapeHtml(String.new tokens[idx].content)
    end

    #------------------------------------------------------------------------------
    def self.html_block(tokens, idx)
      return String.new(tokens[idx].content)
    end
    def self.html_inline(tokens, idx)
      return String.new(tokens[idx].content)
    end

    alias OptionType = NamedTuple(html: Bool, xhtmlOut: Bool, breaks: Bool, langPrefix: String, linkify: Bool, typographer: Bool, quotes: String, highlight: Nil, maxNesting: Int32)

    @rules : Hash(String, Proc(Array(Token), Int32, OptionType, StateEnv, Renderer, String))

    # new Renderer()
    #
    # Creates new [[Renderer]] instance and fill [[Renderer#rules]] with defaults.
    #------------------------------------------------------------------------------
    def initialize
      @rules = {
        "code_inline" => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.code_inline(tokens, idx) },
        "code_block"  => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.code_block(tokens, idx)},
        "fence"       => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.fence(tokens, idx, options, env, renderer)},
        "image"       => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.image(tokens, idx, options, env, renderer)},
        "hardbreak"   => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.hardbreak(tokens, idx, options)},
        "softbreak"   => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.softbreak(tokens, idx, options)},
        "text"        => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.text(tokens, idx)},
        "html_block"  => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.html_block(tokens, idx)},
        "html_inline" => -> (tokens : Array(Token), idx : Int32, options : OptionType, env : StateEnv, renderer : Renderer) { Renderer.html_inline(tokens, idx)}
      }
      
      # Renderer#rules -> Object
      #
      # Contains render rules for tokens. Can be updated and extended.
      #
      # ##### Example
      #
      # ```javascript
      # var md = require("markdown-it")();
      #
      # md.renderer.rules.strong_open  = function () { return "<b>"; };
      # md.renderer.rules.strong_close = function () { return "</b>"; };
      #
      # var result = md.renderInline(...);
      # ```
      #
      # Each rule is called as independed static function with fixed signature:
      #
      # ```javascript
      # function my_token_render(tokens, idx, options, env, renderer) {
      #   // ...
      #   return renderedHTML;
      # }
      # ```
      #
      # See [source code](https://github.com/markdown-it/markdown-it/blob/master/lib/renderer.js)
      # for more details and examples.
      #@rules = @default_rules.dup
    end


    # Renderer.renderAttrs(token) -> String
    #
    # Render token attributes to string.
    #------------------------------------------------------------------------------
    def renderAttrs(token)
      return "" if !token.attrs

      result = ""
      0.upto(token.attrs.size - 1) do |i|
        result += " " + escapeHtml(token.attrs[i][0]) + "=\"" + escapeHtml(token.attrs[i][1].to_s) + "\""
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
    def renderToken(tokens, idx, options, env = nil, renderer = nil)
      result = ""
      needLf = false
      token  = tokens[idx]

      # Tight list paragraphs
      return "" if token.hidden

      # Insert a newline between hidden paragraph and subsequent opening
      # block-level tag.
      #
      # For example, here we should insert a newline before blockquote:
      #  - a
      #    >
      #
      if token.block && token.nesting != -1 && idx && tokens[idx - 1].hidden
        result += "\n"
      end

      # Add token name, e.g. `<img`
      result += (token.nesting == -1 ? "</" : "<") + token.tag

      # Encode attributes, e.g. `<img src="foo"`
      result += renderAttrs(token)

      # Add a slash for self-closing tags, e.g. `<img src="foo" /`
      if token.nesting == 0 && options[:xhtmlOut]
        result += " /"
      end

      # Check if we need to add a newline after this tag
      if token.block
        needLf = true

        if token.nesting == 1
          if idx + 1 < tokens.size
            nextToken = tokens[idx + 1]

            if nextToken.type == "inline" || nextToken.hidden
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

      result += needLf ? ">\n" : ">"

      return result
    end


    # Renderer.renderInline(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # The same as [[Renderer.render]], but for single token of `inline` type.
    #------------------------------------------------------------------------------
    def renderInline(tokens, options, env)
      result  = ""
      rules   = @rules
      0.upto(tokens.size - 1) do |i|
        type = tokens[i].type
        
        if rules[type]?
          result += rules[type].call(tokens, i, options, env, self)
        else
          result += renderToken(tokens, i, options)
        end
      end

      return result;
    end


    # internal
    # Renderer.renderInlineAsText(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # Special kludge for image `alt` attributes to conform CommonMark spec.
    # Don't try to use it! Spec requires to show `alt` content with stripped markup,
    # instead of simple escaping.
    #------------------------------------------------------------------------------
    def renderInlineAsText(tokens, options, env)
      result = ""
      rules  = @rules

      0.upto(tokens.size - 1) do |i|
        if tokens[i].type == "text"
          result += rules["text"].call(tokens, i, options, env, self)
        elsif tokens[i].type == "image"
          result += renderInlineAsText(tokens[i].children, options, env)
        end
      end

      return result
    end


    # Renderer.render(tokens, options, env) -> String
    # - tokens (Array): list on block tokens to renter
    # - options (Object): params of parser instance
    # - env (Object): additional data from parsed input (references, for example)
    #
    # Takes token stream and generates HTML. Probably, you will never need to call
    # this method directly.
    #------------------------------------------------------------------------------
    def render(tokens, options, env)
      result = ""
      rules  = @rules

      0.upto(tokens.size - 1) do |i|
        type = tokens[i].type

        if type == "inline"
          result += renderInline(tokens[i].children, options, env)
        elsif rules[type]?
          result += rules[tokens[i].type].call(tokens, i, options, env, self)
        else
          result += renderToken(tokens, i, options)
        end
      end

      return result
    end

  end
end
