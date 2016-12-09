class Regex
  class ByteMatchData
    getter regex : Regex
    getter size : Int32
    getter buffer : Bytes

    def initialize(@regex : Regex, @code : LibPCRE::Pcre, @buffer : Bytes, @pos : Int32, @ovector : Int32*, @size : Int32)
    end

    def begin(n = 0)
      check_index_out_of_bounds n
      @ovector[n * 2]
    end

    def end(n = 0)
      check_index_out_of_bounds n
      @ovector[n * 2 + 1]
    end

    def []?(n)
      return unless valid_group?(n)

      start = @ovector[n * 2]
      finish = @ovector[n * 2 + 1]
      return if start < 0
      @buffer[start, finish - start]
    end

    def [](n)
      check_index_out_of_bounds n

      self[n]?.not_nil!
    end

    def []?(group_name : String)
      ret = LibPCRE.get_stringnumber(@code, group_name)
      return if ret < 0
      self[ret]?
    end

    def [](group_name : String)
      match = self[group_name]?
      unless match
        raise ArgumentError.new("Match group named '#{group_name}' does not exist")
      end
      match
    end

    def pre_match
      @buffer[0, byte_begin(0)]
    end

    def post_match
      @buffer[byte_end(0)]
    end

    def inspect(io : IO)
      to_s(io)
    end

    def to_s(io : IO)
      name_table = @regex.name_table

      io << "#<Regex::MatchData "
      String.new(self[0]).inspect(io)
      if size > 0
        io << " "
        size.times do |i|
          io << " " if i > 0
          io << name_table.fetch(i + 1) { i + 1 }
          io << ":"
          if self[i + 1]
            String.new(self[i + 1].not_nil!).inspect(io)
          else
            nil.inspect(io)
          end
        end
      end
      io << ">"
    end

    def dup
      self
    end

    def clone
      self
    end

    private def check_index_out_of_bounds(index)
      raise IndexError.new unless valid_group?(index)
    end

    private def valid_group?(index)
      index <= @size
    end
  end

  def bytematch(buffer : Bytes, byte_index = 0, options = Regex::Options::None) : Regex::ByteMatchData?
    return ($~ = nil) if byte_index > buffer.size

    ovector_size = (@captures + 1) * 3
    ovector = Pointer(Int32).malloc(ovector_size)
    ret = LibPCRE.exec(@re, @extra, buffer.to_unsafe, buffer.size, byte_index, (options | Options::NO_UTF8_CHECK), ovector, ovector_size)
    if ret > 0
      match = ByteMatchData.new(self, @re, buffer, byte_index, ovector, @captures)
    else
      match = nil
    end

    $~ = match
  end
end
