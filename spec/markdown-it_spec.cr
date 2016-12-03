require "./spec_helper"

private def assert_render_it(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    parser = MarkdownIt::Parser.new(:markdownit)
    parser.render(input).should eq(output)
  end
end

describe "MarkdownIt Spec" do
  files = Dir.glob "#{__DIR__}/markdown-it/*.txt"
  files.each do |spec_file|
    data = File.read(spec_file)
    source = ""
    result = ""
    example_line = 0
    state = 0
    data.each_line.with_index.each do |line, index|
      if line == ".\n" && state == 0
        example_line = index
        source = ""
        state = 1
        next
      end
      if line == ".\n" && state == 1
        result = ""
        state = 2
        next
      end
      if line == ".\n" && state == 2
        source = source.gsub("→", "\t")
        result = result.gsub("→", "\t")
        assert_render_it source, result, spec_file, example_line
        state = 0
        next
      end
      if state == 1
        source += line
        next
      end
      if state == 2
        result += line
        next
      end
    end
  end
end
