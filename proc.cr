Aproc = -> (state : String, clean : Bool) { puts state.inspect }
Aproc_with_label = { "text", Aproc }

PROCS = [Aproc_with_label]

puts PROCS.inspect
st = "test"

PROCS.each do |proc|
  puts proc[1].inspect
  puts proc[1].call(st, true)
end
