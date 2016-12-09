# Convert straight quotation marks to typographic ones
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesCore
    class Smartquotes
      extend Common::Utils

      QUOTE_TEST_RE = /['"]/
      QUOTE_RE      = /['"]/
      APOSTROPHE    = "\u2019" # ’


      def self.replaceAt(buf : Bytes, index, ch : String) : Bytes
        (String.new(buf[0, index]) + ch + String.new(buf[(index + 1)..-1])).to_slice
      end

      record Quote,
        token : Int32,
        pos : Int32,
        single : Bool,
        level : Int32

      #------------------------------------------------------------------------------
      def self.process_inlines(tokens, state)
        stack = [] of Quote

        (0...tokens.size).each do |i|
          token = tokens[i]

          thisLevel = tokens[i].level

          j = stack.size - 1
          while j >= 0
            break if (stack[j].level <= thisLevel)
            j -= 1
          end

          # stack.size = j + 1
          stack = (j < stack.size ? stack[0...(j + 1)] : stack.fill(Quote.new(-1, 0, true, 0), stack.size...(j+1)))

          next if token.type != :text

          text : Bytes = token.content
          pos  = 0
          max  = text.size
          byteshift = 0

          # OUTER loop
          while pos < max
            continue_outer_loop = false
            t = QUOTE_RE.bytematch(text, pos)
            break if t.nil?

            canOpen  = true
            canClose = true
            pos      = t.begin(0).not_nil! + 1
            isSingle = t[0] == "'".to_slice

            # Find previous character,
            # default to space if it's the beginning of the line
            #
            lastChar = 0x20

            if pos - 2 >= 0
              lastChar = text[pos - 2]
            else
              j = i - 1
              while j >= 0
                if tokens[j].type != :text
                  j -= 1
                  next
                end

                lastChar = tokens[j].content.charCodeAt(tokens[j].content.size - 1)
                break
                j -= 1
              end
            end

            # Find next character,
            # default to space if it's the end of the line
            #
            nextChar = 0x20

            if pos < max
              nextChar = text[pos]
            else
              j = i + 1
              while j < tokens.size
                if tokens[j].type != :text
                  j += 1
                  next
                end

                nextChar = tokens[j].content.charCodeAt(0)
                break
                j += 1
              end
            end

            isLastPunctChar = isMdAsciiPunct(lastChar) || isPunctChar(lastChar.chr.to_s)
            isNextPunctChar = isMdAsciiPunct(nextChar) || isPunctChar(nextChar.chr.to_s)

            isLastWhiteSpace = isWhiteSpace(lastChar)
            isNextWhiteSpace = isWhiteSpace(nextChar)
            if (isNextWhiteSpace)
              canOpen = false
            elsif (isNextPunctChar)
              if (!(isLastWhiteSpace || isLastPunctChar))
                canOpen = false
              end
            end

            if (isLastWhiteSpace)
              canClose = false
            elsif (isLastPunctChar)
              if (!(isNextWhiteSpace || isNextPunctChar))
                canClose = false
              end
            end

            if (nextChar == 0x22 && t[0] == "\"".to_slice) # "
              if (lastChar >= 0x30 && lastChar <= 0x39)   # >= 0  && <= 9
                # special case: 1"" - count first quote as an inch
                canClose = canOpen = false
              end
            end

            if (canOpen && canClose)
              # treat this as the middle of the word
              canOpen  = false
              canClose = isNextPunctChar
            end

            if (!canOpen && !canClose)
              # middle of word
              if (isSingle)
                token.content = replaceAt(token.content, t.begin(0).not_nil! + byteshift, APOSTROPHE)
                byteshift += APOSTROPHE.bytesize - '"'.bytesize
              end
              next
            end


            if (canClose)
              # this could be a closing quote, rewind the stack to get a match
              j = stack.size - 1
              while j >= 0
                item = stack[j]
                break if (stack[j].level < thisLevel)
                if (item.single == isSingle && stack[j].level == thisLevel)
                  item = stack[j]
                  if isSingle
                    openQuote  = state.md.options[:quotes][2].to_s
                    closeQuote = state.md.options[:quotes][3].to_s
                  else
                    openQuote  = state.md.options[:quotes][0].to_s
                    closeQuote = state.md.options[:quotes][1].to_s
                  end

                  # replace token.content *before* tokens[item.token].content,
                  # because, if they are pointing at the same token, replaceAt
                  # could mess up indices when quote length != 1
                  token.content = replaceAt(token.content, t.begin(0).not_nil!, closeQuote)
                  tokens[item.token].content = replaceAt(tokens[item.token].content, item.pos, openQuote)

                  pos += closeQuote.size - 1
                  pos += (openQuote.size - 1) if item.token == i

                  text = token.content
                  max  = text.size

                  # stack.size = j
                  stack = (j < stack.size ? stack[0...j] : stack.fill(Quote.new(-1, 0, true, 0), stack.size...j)) 
                  continue_outer_loop = true    # continue OUTER;
                  break
                end
                j -= 1
              end
            end
            next if continue_outer_loop


            if (canOpen)
              stack.push(Quote.new(
                token: i,
                pos: t.begin(0).not_nil!,
                single: isSingle,
                level: thisLevel
              ))
            elsif (canClose && isSingle)
              token.content = replaceAt(token.content, t.begin(0).not_nil!, APOSTROPHE)
            end
          end
        end
      end

      #------------------------------------------------------------------------------
      def self.smartquotes(state)
        return false if !state.md.options[:typographer]

        blkIdx = state.tokens.size - 1
        while blkIdx >= 0
          if (state.tokens[blkIdx].type != :inline || !(QUOTE_TEST_RE.bytematch(state.tokens[blkIdx].content)))
            blkIdx -= 1
            next
          end

          process_inlines(state.tokens[blkIdx].children, state)
          blkIdx -= 1
        end
        true
      end

    end
  end
end
