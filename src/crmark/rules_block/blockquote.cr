# Block quotes
#------------------------------------------------------------------------------
module MarkdownIt
  module RulesBlock
    class Blockquote

      #------------------------------------------------------------------------------
      def self.blockquote(state, startLine, endLine, silent)
        pos = state.bMarks[startLine] + state.tShift[startLine]
        max = state.eMarks[startLine]

        # check the block quote marker
        return false if state.src.charCodeAt(pos) != 0x3E # >
        pos += 1
        
        # we know that it's going to be a valid blockquote,
        # so no point trying to find the end of it in silent mode
        return true if silent

        oldIndent               = state.blkIndent
        state.blkIndent         = 0

        # skip spaces after ">" and re-calculate offset
        initial = offset = state.sCount[startLine] + pos - (state.bMarks[startLine] + state.tShift[startLine])

        if pos >= state.src.size
          spaceAfterMarker = false
        elsif state.src.charCodeAt(pos) == 0x20 # space
          # skip one optional space after '>'
          # ' >   test '
          #     ^ -- position start of line here:
          pos += 1
          initial += 1
          offset += 1
          adjustTab = false
          spaceAfterMarker = true
        elsif state.src.charCodeAt(pos) == 0x09 # tab
          spaceAfterMarker = true

          if ((state.bsCount[startLine] + offset) % 4 == 3)
            # '  >\t  test '
            #       ^ -- position start of line here (tab has width===1)
            pos += 1
            initial += 1
            offset += 1
            adjustTab = false
          else
            # ' >\t  test '
            #    ^ -- position start of line here + shift bsCount slightly
            #         to make extra space appear
            adjustTab = true
          end
        else
          spaceAfterMarker = false
        end

        oldBMarks               = [ state.bMarks[startLine] ]
        state.bMarks[startLine] = pos

        while pos < max
          ch = state.src.charCodeAt(pos)
          if ch == 0x20 || ch == 0x09
            if ch == 0x09
              offset += 4 - (offset + state.bsCount[startLine] + (adjustTab ? 1 : 0)) % 4
            else
              offset += 1
            end
          else
            break
          end
          pos += 1
        end

        oldBSCount              = [ state.bsCount[startLine] ]
        state.bsCount[startLine]= state.sCount[startLine] + 1 + (spaceAfterMarker ? 1 : 0)

        lastLineEmpty           = pos >= max

        oldSCount               = [ state.sCount[startLine] ]
        state.sCount[startLine] = offset - initial

        oldTShift               = [ state.tShift[startLine] ]
        state.tShift[startLine] = pos - state.bMarks[startLine]

        terminatorRules         = state.md.block.ruler.getRules("blockquote")

        oldParentType    = state.parentType
        state.parentType = "blockquote"

        # Search the end of the block
        #
        # Block ends with either:
        #  1. an empty line outside:
        #     ```
        #     > test
        #
        #     ```
        #  2. an empty line inside:
        #     ```
        #     >
        #     test
        #     ```
        #  3. another tag
        #     ```
        #     > test
        #      - - -
        #     ```
        nextLine = startLine + 1
        while nextLine < endLine
          break if state.sCount[nextLine] < oldIndent
          
          pos = state.bMarks[nextLine] + state.tShift[nextLine]
          max = state.eMarks[nextLine]

          if pos >= max
            # Case 1: line is not inside the blockquote, and this line is empty.
            break
          end

          if state.src.charCodeAt(pos) == 0x3E   # >
            pos += 1
            # This line is inside the blockquote.

            # skip spaces after ">" and re-calculate offset
            initial = offset = state.sCount[nextLine] + pos - (state.bMarks[nextLine] + state.tShift[nextLine]);

            # skip one optional space after '>'
            if state.src.charCodeAt(pos) == 0x20 # space
              # ' >   test '
              #     ^ -- position start of line here:
              pos += 1
              initial += 1
              offset += 1
              adjustTab = false
              spaceAfterMarker = true
            elsif state.src.charCodeAt(pos) == 0x09 # tab
              spaceAfterMarker = true

              if ((state.bsCount[nextLine] + offset) % 4 == 3)
                # '  >\t  test '
                #       ^ -- position start of line here (tab has width===1)
                pos += 1
                initial += 1
                offset += 1
                adjustTab = false
              else
                # ' >\t  test '
                #    ^ -- position start of line here + shift bsCount slightly
                #         to make extra space appear
                adjustTab = true
              end
            else
              spaceAfterMarker = false
            end

            oldBMarks.push(state.bMarks[nextLine])
            state.bMarks[nextLine] = pos

            while pos < max
              ch = state.src.charCodeAt(pos)
              if ch == 0x20 || ch == 0x09
                if ch == 0x09
                  offset += 4 - (offset + state.bsCount[nextLine] + (adjustTab ? 1 : 0)) % 4
                else
                  offset += 1
                end
              else
                break
              end
              pos += 1
            end
            
            lastLineEmpty = pos >= max

            oldBSCount.push(state.bsCount[nextLine])
            state.bsCount[nextLine] = state.sCount[nextLine] + 1 + (spaceAfterMarker ? 1 : 0)

            oldSCount.push(state.sCount[nextLine])
            state.sCount[nextLine] = offset - initial

            oldTShift.push(state.tShift[nextLine])
            state.tShift[nextLine] = pos - state.bMarks[nextLine]
            nextLine += 1
            next
          else
            pos += 1
          end

          # Case 2: line is not inside the blockquote, and the last line was empty.
          break if lastLineEmpty

          # Case 3: another tag found.
          terminate = false
          (0...terminatorRules.size).each do |i|
            if terminatorRules[i].call(state, nextLine, endLine, true)
              terminate = true
              break
            end
          end
          break if terminate

          oldBMarks.push(state.bMarks[nextLine])
          oldBSCount.push(state.bsCount[nextLine])
          oldTShift.push(state.tShift[nextLine])
          oldSCount.push(state.sCount[nextLine])

          # A negative indentation means that this is a paragraph continuation
          #
          # Any negative number will do the job here, but it's better for it
          # to be large enough to make any bugs obvious.
          state.sCount[nextLine] = -1
          nextLine += 1
        end

        token            = state.push(:blockquote_open, "blockquote", 1)
        token.markup     = ">"
        token.map        = lines = [ startLine, 0 ]

        state.md.block.tokenize(state, startLine, nextLine)

        token            = state.push(:blockquote_close, "blockquote", -1)
        token.markup     = ">"

        state.parentType = oldParentType
        lines[1]         = state.line

        # Restore original tShift; this might not be necessary since the parser
        # has already been here, but just to make sure we can do that.
        (0...oldTShift.size).each do |i|
          state.bMarks[i + startLine] = oldBMarks[i]
          state.tShift[i + startLine] = oldTShift[i]
          state.sCount[i + startLine] = oldSCount[i]
          state.bsCount[i + startLine] = oldBSCount[i]
        end
        state.blkIndent = oldIndent
        return true
      end

    end
  end
end
