# Replace link-like texts with link nodes.
#
# Currently restricted by `md.validateLink()` to http/https/ftp
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Linkify
      MAILTO_RE  = /^mailto\:/
      
      #------------------------------------------------------------------------------
      def self.isLinkOpen(str : Bytes)
        return !(/^<a[>\s]/i.bytematch str).nil?
      end

      def self.isLinkClose(str : Bytes)
        return !(/^<\/a\s*>/i.bytematch str).nil?
      end

      #------------------------------------------------------------------------------
      def self.linkify(state)
        blockTokens = state.tokens

        return false if (!state.md.options[:linkify])

        (0...blockTokens.size).each do |j|
          if (blockTokens[j].type != :inline || !LinkifyIt.pretest(blockTokens[j].content))
            next
          end

          tokens = blockTokens[j].children

          htmlLinkLevel = 0

          # We scan from the end, to keep position when new tags added.
          # Use reversed logic in links start/end match
          i = tokens.size - 1
          while i >= 0
            currentToken = tokens[i]

            # Skip content of markdown links
            if (currentToken.type == :link_close)
              i -= 1
              while (tokens[i].level != currentToken.level && tokens[i].type != :link_open)
                i -= 1
              end
              i -= 1
              next
            end

            # Skip content of html tag links
            if (currentToken.type == :html_inline)
              if isLinkOpen(currentToken.content) && htmlLinkLevel > 0
                htmlLinkLevel -= 1
              end
              if isLinkClose(currentToken.content)
                htmlLinkLevel += 1
              end
            end
            if (htmlLinkLevel > 0)
              i -= 1
              next 
            end

            if (currentToken.type == :text && LinkifyIt.pretest(currentToken.content))
              text = currentToken.content
              links = LinkifyIt.match(text)

              # Now split string to nodes
              nodes   = [] of Token
              level   = currentToken.level
              lastPos = 0
              
              (0...links.size).each do |ln|
                url = links[ln].url
                fullUrl = state.md.normalizeLink.call(url)
                next if (!state.md.validateLink.call(fullUrl))

                urlText = links[ln].text

                # Linkifier might send raw hostnames like "example.com", where url
                # starts with domain name. So we prepend http:// in those cases,
                # and remove it afterwards.
                if links[ln].schema.empty?
                  urlText = state.md.normalizeLinkText.call("http://#{urlText}").sub(/^http:\/\//, "")
                elsif (links[ln].schema == "mailto:" && !(MAILTO_RE.match urlText))
                  urlText = state.md.normalizeLinkText.call("mailto:#{urlText}").sub(MAILTO_RE, "")
                else
                  urlText = state.md.normalizeLinkText.call(urlText)
                end

                pos = links[ln].index

                if (pos > lastPos)
                  token         = Token.new(:text, "", 0)
                  token.content = text[lastPos...pos].to_slice
                  token.level   = level
                  nodes.push(token)
                end

                token         = Token.new(:link_open, "a", 1)
                token.attrs   = [ [ "href", fullUrl ] ]
                token.level   = level
                level        += 1
                token.markup  = "linkify"
                token.info    = :auto
                nodes.push(token)

                token         = Token.new(:text, "", 0)
                token.content = urlText.to_slice
                token.level   = level
                nodes.push(token)

                token         = Token.new(:link_close, "a", -1)
                level        -= 1
                token.level   = level
                token.markup  = "linkify"
                token.info    = :auto
                nodes.push(token)

                lastPos = links[ln].lastIndex
              end

              if (lastPos < text.size)
                token         = Token.new(:text, "", 0)
                token.content = text[lastPos..-1].to_slice
                token.level   = level
                nodes.push(token)
              end

              # replace current node
              tokens[i..i] = nodes
              blockTokens[j].children = tokens
            end
            i -= 1
          end
        end
        true
      end
    end
  end
end
