# Commonmark default options

module MarkdownIt
  module Presets
    class MarkdownIt
      def self.options
        {
          options: {
            html:         true,         # Enable HTML tags in source
            xhtmlOut:     false,        # Use '/' to close single tags (<br />)
            breaks:       false,        # Convert '\n' in paragraphs into <br>
            langPrefix:   "",           # CSS language prefix for fenced blocks
            linkify:      true,         # autoconvert URL-like texts to links

            # Enable some language-neutral replacements + quotes beautification
            typographer:  true,

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

            maxNesting:   20            # Internal protection, recursion limit
          },

          components: {

            core: {
              rules: [
                "normalize",
                "block",
                "inline",
                "linkify",
                "replacements",
                "smartquotes",
              ]
            },

            block: {
              rules: [
                "blockquote",
                "code",
                "fence",
                "heading",
                "hr",
                "html_block",
                "lheading",
                "list",
                "reference",
                "paragraph",
                "table",
              ]
            },

            inline: {
              rules: [
                "autolink",
                "backticks",
                "strikethrough",
                "emphasis",
                "entity",
                "escape",
                "html_inline",
                "image",
                "link",
                "newline",
                "text"
              ],
              rules2: [
                "balance_pairs",
                "strikethrough",
                "emphasis",
                "text_collapse"
              ]
            }
          }
        }
      end
    end
  end
end
