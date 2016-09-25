# Simple typographyc replacements
#
# (c) (C) → ©
# (tm) (TM) → ™
# (r) (R) → ®
# +- → ±
# (p) (P) -> §
# ... → … (also ?.... → ?.., !.... → !..)
# ???????? → ???, !!!!! → !!!, `,,` → `,`
# -- → &ndash;, --- → &mdash;
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Replacements

      # TODO (from original)
      # - fractionals 1/2, 1/4, 3/4 -> ½, ¼, ¾
      # - miltiplication 2 x 4 -> 2 × 4

      RARE_RE = /\+-|\.\.|\?\?\?\?|!!!!|,,|--/

      SCOPED_ABBR_RE = /\((c|tm|r|p)\)/i
      SCOPED_ABBR = {
        "c" => "©",
        "r" => "®",
        "p" => "§",
        "tm" => "™"
      }

      #------------------------------------------------------------------------------
      def self.replaceFn(match, name)
        return SCOPED_ABBR[name.downcase]
      end

      #------------------------------------------------------------------------------
      def self.replace_scoped(inlineTokens)
        (inlineTokens.size - 1).downto(0) do |i|
          token = inlineTokens[i]
          if (token.type == "text")
            token.content = (String.new(token.content).gsub(SCOPED_ABBR_RE) {|match| self.replaceFn(match, $1)}).to_slice # !!!
          end
        end
      end

      #------------------------------------------------------------------------------
      def self.replace_rare(inlineTokens)
        (inlineTokens.size - 1).downto(0) do |i|
          token = inlineTokens[i]
          if (token.type == "text")
            strcontent = String.new token.content
            if RARE_RE.match(strcontent)
              strcontent = strcontent.
                          gsub(/\+-/, "±").
                          # .., ..., ....... -> …
                          # but ?..... & !..... -> ?.. & !..
                          gsub(/\.{2,}/, "…").gsub(/([?!])…/, "\\1..").
                          gsub(/([?!]){4,}/, "\\1\\1\\1").gsub(/,{2,}/, ",").
                          # em-dash
                          gsub(/(^|[^-])---([^-]|$)/m, "\\1\u2014\\2").
                          # en-dash
                          gsub(/(^|\s)--(\s|$)/m, "\\1\u2013\\2").
                          gsub(/(^|[^-\s])--([^-\s]|$)/m, "\\1\u2013\\2")
              token.content = strcontent.to_slice
            end
          end
        end
      end


      #------------------------------------------------------------------------------
      def self.replace(state)
        return false if (!state.md.options[:typographer])

        (state.tokens.size - 1).downto(0) do |blkIdx|
          next if (state.tokens[blkIdx].type != "inline")

          if SCOPED_ABBR_RE.match(String.new state.tokens[blkIdx].content)
            replace_scoped(state.tokens[blkIdx].children)
          end

          if RARE_RE.match(String.new state.tokens[blkIdx].content)
            replace_rare(state.tokens[blkIdx].children)
          end

        end
        true
      end

    end
  end
end
