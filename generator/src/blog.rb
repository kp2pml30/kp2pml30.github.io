# frozen_string_literal: true

require 'haml'
require 'plurimath'

HIGHLIGHTS = {
  /\b(?:[A-Z][a-zA-Z\-_0-9]*)\b*/ => 'type',
  /#(\s|$)[^\n]*/ => 'comment',
  /\b(?:open|final|class|fn|let|var|if|else|while|loop|return|namespace|new)\b/ => 'kw',
  /\b(?:null|undefined|true|false|this|self)\b/i => 'const',
  /[:,;()\[\]{}<>]/ => 'punct',
  /0|(0x[0-9a-fA-F]+)|([1-9][0-9]*(\.[0-9]+)?)/ => 'number',
  /"(?:\\.|[^\\"])*"/ => 'str',
  /'(?:\\.|[^\\'])*'/ => 'str',
}

def highlight(txt)
  idx = 0
  res = String.new
  old_idx = 0
  flush = Proc.new {
    next if old_idx == idx
    res << ERB::Util.html_escape(txt[old_idx...idx])
    old_idx = idx
  }
  while idx < txt.size
    pattern = nil
    HIGHLIGHTS.each { |pat, klass|
      match = pat.match txt, idx
      next if not match
      next if match.offset(0)[0] != idx
      pattern = pat
      flush.()
      res << "<span class=\"highlight-#{klass}\">" << ERB::Util.html_escape(match[0]) << "</span>"
      idx += match[0].size
      old_idx = idx
      break
    }
    if pattern.nil?
      idx += 1
    end
  end
  flush.()
  res.freeze
end

class Kp2Code < Haml::Filters::Base
  def compile(node)
    temple = [:multi]
    temple << [:static, "<pre><code>"]
    temple << [:static, highlight(node.value[:text])]
    temple << [:static, "\n</code></pre>"]
    temple
  end
end

class Plurimath::Math::Formula
  def unitsml_post_processing_pub(*args, **kwargs, &blk)
    unitsml_post_processing(*args, **kwargs, &blk)
  end
end

def highlight_md(txt)
  temple = [:multi]
  idx = 0
  old_idx = 0

  flush = Proc.new {
    next if old_idx == idx
    temple << [:static, txt[old_idx...idx]]
    old_idx = idx
  }

  while idx < txt.size
    if txt[idx] == '`'
      flush.()
      idx += 1
      last_idx = txt.index('`', idx)
      raise "no ` in #{txt[idx...]}" if last_idx.nil?
      temple << [:static, '<code class="inline">']
      temple << [:static, highlight(txt[idx...last_idx])]
      temple << [:static, '</code>']
      idx = last_idx + 1
      old_idx = idx
    elsif txt[idx...idx + 2] == "$$"
      flush.()
      idx += 2
      last_idx = txt.index('$$', idx)
      formula = Plurimath::Math.parse(txt[idx...last_idx], :asciimath)
      math = formula.to_mathml_without_math_tag(false, options: { display_style: 'inline' })
      formula.unitsml_post_processing_pub(math.nodes, math)
      temple << [:static, "<math><mstyle displaystyle='true'>"]
      temple << [:static, formula.dump_nodes(math, indent: 2)]
      temple << [:static, "</mstyle></math>"]
      idx = last_idx + 2
      old_idx = idx
    else
      idx += 1
    end
  end
  flush.()
  temple
end

class Kp2Md < Haml::Filters::Base
  def compile(node)
    highlight_md(node.value[:text])
  end
end

def render_head(txt, path)
  temple = [:multi]
  hash = eval(txt)
  temple << [:static, "<h1>"]
  temple << highlight_md(hash[:title])
  temple << [:static, "</h1>\n"]
  temple << [:static, '<hr/>']
  temple << [:static, "Raw source: <a href=\"/fs-tree/#{path}\">link</a>"]
  temple << [:static, '<hr/>']
  temple
end

Haml::Filters.registered[:kp2code] ||= Kp2Code
Haml::Filters.registered[:kp2md] ||= Kp2Md

module KP2PML30Blog
  def self.generate(path, tree_root)
    blog_text = path.read
    match = /^\#\#\# body \#\#\#$/.match blog_text
    raise "no magic comment" if not match

    head = blog_text[...match.offset(0)[0]]

    gen = Temple::Generators::ArrayBuffer.new
    head_rendered = eval(gen.call(render_head(head, path.relative_path_from(tree_root))))

    blog_text = blog_text[match.offset(0)[1]...]

    engine = Haml::Template.new { blog_text }
    result_text = engine.render
    res_path = path.sub_ext('')
    res_path.write(head_rendered + "\n" + result_text)
    res_path
  end
end
