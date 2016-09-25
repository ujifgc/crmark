struct UInt8
  def space_tab?
    self == 0x20 || self == 0x09
  end

  def whitespace?
    self == 0x20 || 0x09 <= self <= 0x0D
  end
end

struct Slice(T)
  def charCodeAt(ch)
    self[ch]
  end

  def [](range : Range(Int, Int))
    from, size = range_to_index_and_size(range)
    self[from, size]
  end

  def strip
    sl = self
    left_nonspace = 0
    while left_nonspace < size && sl[left_nonspace].whitespace?
      left_nonspace += 1
    end
    right_nonspace = size - 1
    while right_nonspace > left_nonspace && sl[right_nonspace].whitespace?
      right_nonspace -= 1
    end
    left_nonspace > right_nonspace ? self.class.new(0) : sl[left_nonspace..right_nonspace]
  end

  private def range_to_index_and_size(range)
    from = range.begin
    from += size if from < 0
    raise IndexError.new if from < 0

    to = range.end
    to += size if to < 0
    to -= 1 if range.excludes_end?
    size = to - from + 1
    size = 0 if size < 0

    {from, size}
  end
end
