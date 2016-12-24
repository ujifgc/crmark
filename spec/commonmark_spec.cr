require "./spec_helper"

private def assert_render(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    parser = MarkdownIt::Parser.new(:commonmark)
    parser.render(input).should eq(output)
  end
end

describe "CommonMark parser" do
  spec_file = "#{__DIR__}/commonmark/spec.txt"
  data = File.read(spec_file)
  source = nil
  result = nil
  example_line = 0
  data.each_line(chomp: false).with_index.each do |line, index|
    if line == "`"*32 + " example\n"
      example_line = index
      source = ""
      next
    end
    if line == ".\n"
      result = ""
      next
    end
    if line == "`"*32 + "\n" && source && result
      assert_render source, result, spec_file, example_line
      source = nil
      result = nil
      next
    end
    if result
      result += line.tr("→", "\t")
      next
    elsif source
      source += line.tr("→", "\t")
      next
    end
  end
end
