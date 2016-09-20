class String
  
  # grab the remainder of the string starting at 'start'
  #------------------------------------------------------------------------------
  def slice_to_end(start)
    self[start...self.size]
  end
  
  # port of Javascript function charCodeAt
  #------------------------------------------------------------------------------
  def charCodeAt(ch)
    self[ch].ord
  end

  def isSpace
    strip.empty?
  end
end