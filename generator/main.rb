#!/usr/bin/env ruby

# frozen_string_literal: true

require 'pathname'
require 'json'

require_relative './src/blog.rb'

root = Pathname.new(__FILE__).parent.parent
tree_root = root.join('public', 'fs-tree')
trie = {
  "kind" => "dir",
  "name" => "",
  "sub" => {}
}
tree_root.glob('**/*').each { |p|
  next if not p.file?
  next if p.to_s.end_with? '.meta.json'
  next if p.to_s.end_with? '.blog'
  meta = {
    "date": "???? ?? ??"
  }
  if p.to_s.end_with? '.blog.haml'
    p = KP2PML30Blog::generate p, tree_root
  else
    meta_path = p.sub_ext('.meta.json')
    if meta_path.exist?
      meta = JSON.parse(meta_path.read())
    end
  end
  rel_path = p.relative_path_from tree_root
  cur_trie = trie
  path_comps = rel_path.to_s.split('/')
  path_comps.each_with_index { |cur, idx|
    if idx + 1 == path_comps.size
      cur_trie["sub"][cur] = {
        "kind" => "file",
        "name" => cur,
        "meta" => meta,
      }
      next
    end
    if not cur_trie["sub"].has_key?(cur)
      cur_trie["sub"][cur] = {
        "kind" => "dir",
        "name" => cur,
        "sub" => {}
      }
    end
    cur_trie = cur_trie["sub"][cur]
  }
}

def rec(val)
  if val["kind"] == "dir"
    val["sub"] = val["sub"].values.map { |v| rec v }
    val["sub"].sort_by! { |v|
      [v["kind"], v["name"]]
    }
  end
  val
end

trie = rec trie

root.join('src', 'tree.json').write(JSON.dump(trie))
