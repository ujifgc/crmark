require "./spec_helper"

require "spec"
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
  i = 0
  common_mark_examples.each do |example|
    i += 1
    assert_render example.markdown, example.html, examples_file, example.example
  end
end
