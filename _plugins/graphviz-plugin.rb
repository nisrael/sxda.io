# frozen_string_literal: true

=begin
Allows to use the following in templates:

{% graphviz some title %}
digraph G {
  node [shape=box]
  edge [color = "#aaaaaa"]
  overlap = "false"
  nodesep = 1

  sda2 [label="sda2", color="#ffd44f"]
  sdb2 [label="sdb2", color="#ffd44f"]

  md1 [label="mdraid mirror (md1)", color="#ffd44f"]

  sda2, sdb2 -> md1
}
{% endgraphviz %}

Which will generate the graph using `dot` command,
and output the result as `img` tag with proper title.

Alternatively, you can leave out the title out,
in which case it will be set to `inlined graphviz graph`.

And if you use `graphviz_captioned` block instead of `graphviz`,
the title will also end up as a caption below the image.
=end

require "jekyll"
require 'open3'
require 'cgi'
require 'base64'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module Jekyll
  class RenderGraphvizBlock < Liquid::Block
    def initialize(tag_name, text, tokens)
      super
      @caption = !!(tag_name =~ /captioned/)
      @title = text && text.strip
    end

    def gen_svg(input)
      output, status = Open3.capture2e("dot -Tsvg", stdin_data: input, binmode: true)
      output.force_encoding 'UTF-8'
      if status.success?
        [output, nil]
      else
        [nil, output]
      end
    end

    def render(context)
      text = super
      output, error = gen_svg(text.strip)
      if error
        "<pre><code>" + CGI.escapeHTML(error) + "</code></pre>"
      else
        title = @title || "inlined graphviz graph"
        b64 = Base64.strict_encode64(output)
        out = []
        out << "<p>"
        out << "<img alt=\"#{CGI.escapeHTML(title)}\" "
        out << "src=\"data:image/svg+xml;base64,#{b64}\" />"
        if @caption
          out << "\n<em>#{CGI.escapeHTML(title)}</em>"
        end
        out << "</p>"
        out.join
      end
    end
  end
end

Liquid::Template.register_tag('graphviz', Jekyll::RenderGraphvizBlock)
Liquid::Template.register_tag('graphviz_captioned', Jekyll::RenderGraphvizBlock)
