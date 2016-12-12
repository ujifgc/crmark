# Main parser class
#------------------------------------------------------------------------------
require "uri"
require "./presets/*"
require "./parser_state"

CONFIG = {
  :default    => MarkdownIt::Presets::Default.options,
  :zero       => MarkdownIt::Presets::Zero.options,
  :commonmark => MarkdownIt::Presets::Commonmark.options,
  :markdownit => MarkdownIt::Presets::MarkdownIt.options,
}

RECODE_HOSTNAME_FOR = [ "http:", "https:", "mailto:" ]

#------------------------------------------------------------------------------
# class MarkdownIt
# 
# Main parser/renderer class.
# 
# ##### Usage
# 
# ```javascript
# // node.js, "classic" way:
# var MarkdownIt = require('markdown-it'),
#     md = new MarkdownIt();
# var result = md.render('# markdown-it rulezz!');
# 
# // node.js, the same, but with sugar:
# var md = require('markdown-it')();
# var result = md.render('# markdown-it rulezz!');
# 
# // browser without AMD, added to "window" on script load
# // Note, there are no dash.
# var md = window.markdownit();
# var result = md.render('# markdown-it rulezz!');
# ```
# 
# Single line rendering, without paragraph wrap:
# 
# ```javascript
# var md = require('markdown-it')();
# var result = md.renderInline('__markdown-it__ rulezz!');
# ```
#------------------------------------------------------------------------------
module MarkdownIt
  class Parser
    include MarkdownIt::Common::Utils

    property :inline
    property :block
    property :core
    property :options

    # new MarkdownIt([presetName, options])
    # - presetName (String): optional, `commonmark` / `zero`
    # - options (Object)
    #
    # Creates parser instanse with given config. Can be called without `new`.
    #
    # ##### presetName
    #
    # MarkdownIt provides named presets as a convenience to quickly
    # enable/disable active syntax rules and options for common use cases.
    #
    # - ["commonmark"](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/commonmark.js) -
    #   configures parser to strict [CommonMark](http://commonmark.org/) mode.
    # - [default](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/default.js) -
    #   similar to GFM, used when no preset name given. Enables all available rules,
    #   but still without html, typographer & autolinker.
    # - ["zero"](https://github.com/markdown-it/markdown-it/blob/master/lib/presets/zero.js) -
    #   all rules disabled. Useful to quickly setup your config via `.enable()`.
    #   For example, when you need only `bold` and `italic` markup and nothing else.
    #
    # ##### options:
    #
    # - __html__ - `false`. Set `true` to enable HTML tags in source. Be careful!
    #   That's not safe! You may need external sanitizer to protect output from XSS.
    #   It's better to extend features via plugins, instead of enabling HTML.
    # - __xhtmlOut__ - `false`. Set `true` to add '/' when closing single tags
    #   (`<br />`). This is needed only for full CommonMark compatibility. In real
    #   world you will need HTML output.
    # - __breaks__ - `false`. Set `true` to convert `\n` in paragraphs into `<br>`.
    # - __langPrefix__ - `language-`. CSS language class prefix for fenced blocks.
    #   Can be useful for external highlighters.
    # - __linkify__ - `false`. Set `true` to autoconvert URL-like text to links.
    # - __typographer__  - `false`. Set `true` to enable [some language-neutral
    #   replacement](https://github.com/markdown-it/markdown-it/blob/master/lib/rules_core/replacements.js) +
    #   quotes beautification (smartquotes).
    # - __quotes__ - `“”‘’`, String or Array. Double + single quotes replacement
    #   pairs, when typographer enabled and smartquotes on. For example, you can
    #   use `'«»„“'` for Russian, `'„“‚‘'` for German, and
    #   `['«\xA0', '\xA0»', '‹\xA0', '\xA0›']` for French (including nbsp).
    # - __highlight__ - `nil`. Highlighter function for fenced code blocks.
    #   Highlighter `function (str, lang)` should return escaped HTML. It can also
    #   return nil if the source was not changed and should be escaped externaly.
    #
    # ##### Example
    #
    # ```javascript
    # // commonmark mode
    # var md = require('markdown-it')('commonmark');
    #
    # // default mode
    # var md = require('markdown-it')();
    #
    # // enable everything
    # var md = require('markdown-it')({
    #   html: true,
    #   linkify: true,
    #   typographer: true
    # });
    # ```
    #
    # ##### Syntax highlighting
    #
    # ```js
    # var hljs = require('highlight.js') // https://highlightjs.org/
    #
    # var md = require('markdown-it')({
    #   highlight: function (str, lang) {
    #     if (lang && hljs.getLanguage(lang)) {
    #       try {
    #         return hljs.highlight(lang, str).value;
    #       } catch (__) {}
    #     }
    #
    #     try {
    #       return hljs.highlightAuto(str).value;
    #     } catch (__) {}
    #
    #     return ''; // use external default escaping
    #   }
    # });
    # ```
    #-----------------------------------------------------------------------------
    def initialize(presetName = :default)
      # MarkdownIt#inline -> ParserInline
      #
      # Instance of [[ParserInline]]. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @inline = ParserInline.new

      # MarkdownIt#block -> ParserBlock
      #
      # Instance of [[ParserBlock]]. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @block = ParserBlock.new

      # MarkdownIt#core -> Core
      #
      # Instance of [[Core]] chain executor. You may need it to add new rules when
      # writing plugins. For simple rules control use [[MarkdownIt.disable]] and
      # [[MarkdownIt.enable]].
      @core = ParserCore.new

      #  Expose utils & helpers for easy acces from plugins

      @options = {
        html:         false,        # Enable HTML tags in source
        xhtmlOut:     false,        # Use '/' to close single tags (<br />)
        breaks:       false,        # Convert '\n' in paragraphs into <br>
        langPrefix:   "language-",  # CSS language prefix for fenced blocks
        linkify:      false,        # autoconvert URL-like texts to links

        # Enable some language-neutral replacements + quotes beautification
        typographer:  false,

        # Double + single quotes replacement pairs, when typographer enabled,
        # and smartquotes on. Could be either a String or an Array.
        #
        # For example, you can use '«»„“' for Russian, '„“‚‘' for German,
        # and ['«\xA0', '\xA0»', '‹\xA0', '\xA0›'] for French (including nbsp).
        quotes: "\u201c\u201d\u2018\u2019", # “”‘’ 

        # Highlighter function. Should return escaped HTML,
        # or '' if input not changed
        #
        # function (/*str, lang*/) { return ''; }
        #
        highlight: nil,

        maxNesting:   20,            # Internal protection, recursion limit
      }

      configure(presetName)
    end


    # chainable
    # MarkdownIt.set(options)
    #
    # Set parser options (in the same format as in constructor). Probably, you
    # will never need it, but you can change options after constructor call.
    #
    # ##### Example
    #
    # ```javascript
    # var md = require('markdown-it')()
    #             .set({ html: true, breaks: true })
    #             .set({ typographer, true });
    # ```
    #
    # __Note:__ To achieve the best possible performance, don't modify a
    # `markdown-it` instance options on the fly. If you need multiple configurations
    # it's best to create multiple instances and initialize each with separate
    # config.
    #------------------------------------------------------------------------------
    def set(options)
      @options = options
      return self
    end


    # chainable, internal
    # MarkdownIt.configure(presets)
    #
    # Batch load of all options and compenent settings. This is internal method,
    # and you probably will not need it. But if you with - see available presets
    # and data structure [here](https://github.com/markdown-it/markdown-it/tree/master/lib/presets)
    #
    # We strongly recommend to use presets instead of direct config loads. That
    # will give better compatibility with next versions.
    #------------------------------------------------------------------------------
    def configure(presets)
      raise("Wrong `markdown-it` preset, can\'t be empty") unless presets

      unless presets.is_a? Hash
        presetName  = presets
        presets     = CONFIG[presetName]
        raise("Wrong `markdown-it` preset #{presetName}, check name") unless presets
      end
      self.set(presets[:options]) if presets[:options]

      inline.ruler.enableOnly(presets[:components][:inline][:rules])
      inline.ruler2.enableOnly(presets[:components][:inline][:rules2])
      block.ruler.enableOnly(presets[:components][:block][:rules])
      core.ruler.enableOnly(presets[:components][:core][:rules])

      return self
    end


    # chainable
    # MarkdownIt.enable(list, ignoreInvalid)
    # - list (String|Array): rule name or list of rule names to enable
    # - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    #
    # Enable list or rules. It will automatically find appropriate components,
    # containing rules with given names. If rule not found, and `ignoreInvalid`
    # not set - throws exception.
    #
    # ##### Example
    #
    # ```javascript
    # var md = require('markdown-it')()
    #             .enable(['sub', 'sup'])
    #             .disable('smartquotes');
    # ```
    #------------------------------------------------------------------------------
    def enable(list, ignoreInvalid = false)
      result = [] of Rule

      list = [ list ] if !list.is_a? Array

      result << @core.ruler.enable(list, true)
      result << @block.ruler.enable(list, true)
      result << @inline.ruler.enable(list, true)
      result << @inline.ruler2.enable(list, true)
      result.flatten!
      
      missed = list.select {|name| !result.include?(name) }
      if !(missed.empty? || ignoreInvalid)
        raise "MarkdownIt. Failed to enable unknown rule(s): #{missed}"
      end

      return self
    end


    # chainable
    # MarkdownIt.disable(list, ignoreInvalid)
    # - list (String|Array): rule name or list of rule names to disable.
    # - ignoreInvalid (Boolean): set `true` to ignore errors when rule not found.
    #
    # The same as [[MarkdownIt.enable]], but turn specified rules off.
    #------------------------------------------------------------------------------
    def disable(list, ignoreInvalid = false)
      result = [] of Rule

      list = [ list ] if !list.is_a? Array

      result << @core.ruler.disable(list, true)
      result << @block.ruler.disable(list, true)
      result << @inline.ruler.disable(list, true)
      result << @inline.ruler2.disable(list, true)
      result.flatten!

      missed = list.select {|name| !result.include?(name) }
      if !(missed.empty? || ignoreInvalid)
        raise StandardError, "MarkdownIt. Failed to disable unknown rule(s): #{missed}"
      end

      return self
    end


    # chainable
    # MarkdownIt.use(plugin, params)
    #
    # Initialize and Load specified plugin with given params into current parser
    # instance. It's just a sugar to call `plugin.init_plugin(md, params)`
    #
    # ##### Example
    #
    # ```ruby
    # md = MarkdownIt::Parser.new
    # md.use(MDPlugin::Iterator, 'foo_replace', 'text', 
    #        lambda {|tokens, idx|
    #          tokens[idx].content = tokens[idx].content.gsub(/foo/, 'bar')
    # })
    # ```
    def use(plugin, *args)
      plugin.init_plugin(self, *args)
      return self
    end


    # internal
    # MarkdownIt.parse(src, env) -> Array
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Parse input string and returns list of block tokens (special token type
    # "inline" will contain list of inline tokens). You should not call this
    # method directly, until you write custom renderer (for example, to produce
    # AST).
    #
    # `env` is used to pass data between "distributed" rules and return additional
    # metadata like reference info, needed for for renderer. It also can be used to
    # inject data in specific cases. Usually, you will be ok to pass `{}`,
    # and then pass updated object to renderer.
    #------------------------------------------------------------------------------
    def parse(src, env)
      state = RulesCore::StateCore.new(src, self, env)
      @core.process(state)
      state.tokens
    end

    # MarkdownIt.render(src [, env]) -> String
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Render markdown string into html. It does all magic for you :).
    #
    # `env` can be used to inject additional metadata (`{}` by default).
    # But you will not need it with high probability. See also comment
    # in [[MarkdownIt.parse]].
    #------------------------------------------------------------------------------
    def render(src, env = clean_env)
      buffer = src.to_slice
      Renderer.new(parse(buffer, env), @options).render
    end

    #------------------------------------------------------------------------------
    def to_html(src, env = clean_env)
      render(src, env)
    end

    # internal
    # MarkdownIt.parseInline(src, env) -> Array
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # The same as [[MarkdownIt.parse]] but skip all block rules. It returns the
    # block tokens list with the single `inline` element, containing parsed inline
    # tokens in `children` property. Also updates `env` object.
    #------------------------------------------------------------------------------
    def parseInline(src, env)
      state = RulesCore::StateCore.new(src, self, env)
      state.inlineMode  = true
      @core.process(state)
      state.tokens
    end

    # MarkdownIt.renderInline(src [, env]) -> String
    # - src (String): source string
    # - env (Object): environment sandbox
    #
    # Similar to [[MarkdownIt.render]] but for single paragraph content. Result
    # will NOT be wrapped into `<p>` tags.
    #------------------------------------------------------------------------------
    def renderInline(src, env = clean_env)
      Renderer.new(parseInline(src, env), @options).render
    end

  end
end
