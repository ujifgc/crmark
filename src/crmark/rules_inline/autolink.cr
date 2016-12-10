# Process autolinks '<protocol:...>'
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesInline
    class Autolink

      EMAIL_RE    = /^<([a-zA-Z0-9.!#$\%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)>/
      AUTOLINK_RE = /^<([a-zA-Z][a-zA-Z0-9+.\-]{1,31}):([^<>\x00-\x20]*)>/

      #------------------------------------------------------------------------------
      def self.autolink(state, silent)
        pos = state.pos

        return false if state.src[pos] != 0x3C  # <

        next_newline = state.src.index('\n'.ord) || -1
        tail = state.src[pos..next_newline]

        return false if !tail.includes?('>'.ord)

        if linkMatch = AUTOLINK_RE.bytematch(tail)
          url = String.new linkMatch[0][1...-1]
          fullUrl = state.md.normalizeLink.call(url)
          return false if !state.md.validateLink.call(fullUrl)

          if (!silent)
            token         = state.push(:link_open, "a", 1)
            token.attrs   = [ [ "href", fullUrl ] ]
            token.markup  = "autolink"
            token.info    = :auto

            token         = state.push(:text, "", 0)
            token.content = state.md.normalizeLinkText.call(url).to_slice

            token         = state.push(:link_close, "a", -1)
            token.markup  = "autolink"
            token.info    = :auto
          end

          state.pos += linkMatch[0].bytesize
          return true
        end

        if emailMatch = EMAIL_RE.bytematch(tail)
          url = String.new emailMatch[0][1...-1]
          fullUrl = state.md.normalizeLink.call("mailto:" + url)
          return false if !state.md.validateLink.call(fullUrl)

          if (!silent)
            token         = state.push(:link_open, "a", 1)
            token.attrs   = [ [ "href", fullUrl ] ]
            token.markup  = "autolink"
            token.info    = :auto

            token         = state.push(:text, "", 0)
            token.content = state.md.normalizeLinkText.call(url).to_slice

            token         = state.push(:link_close, "a", -1)
            token.markup  = "autolink"
            token.info    = :auto
          end

          state.pos += emailMatch[0].bytesize
          return true
        end

        return false
      end

    end
  end
end
