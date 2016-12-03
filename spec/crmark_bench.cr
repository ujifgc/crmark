require "../src/crmark"
require "benchmark"
require "markdown"

Parser = MarkdownIt::Parser.new(:commonmark)

def benchmark(file)
  puts "Benchmarking #{file}"
  input = File.read(file)
  Benchmark.ips(warmup: 0.1, calculation: 0.3) do |x|
    x.report("crmark") { Parser.render(input) }
    x.report("markdown") { Markdown.to_html(input) }
  end
end

Dir.glob("#{__DIR__}/benchmark/samples/*").each do |file|
  benchmark file
end
