require "./spec_helper"

require "spec"
require "markdown"
require "json"

class CommonMarkExample
  JSON.mapping(
    end_line: Int32,
    example: Int32,
    start_line: Int32,
    markdown: String,
    html: String,
    section: String
  )
end

private def assert_render(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    parser = MarkdownIt::Parser.new(:commonmark)
    parser.render(input).should eq(output)
  end
end

describe MarkdownIt do
  examples_file = "#{__DIR__}/CommonMark.json"
  common_mark_examples = Array(CommonMarkExample).from_json File.read(examples_file)
  common_mark_examples.each do |example|
    assert_render example.markdown, example.html.chomp, examples_file, example.start_line
    break
  end

#  it "works" do
#    parser = MarkdownIt::Parser.new(:commonmark)
#    puts parser.render("# markdown-it in **Ruby**")
#  end
end
