#!/usr/bin/env ruby

require 'pathname'
require 'json'

root = Pathname.new(__FILE__).parent
tree_root = root.join('public', 'fs-tree')
trie = {
  "kind" => "dir",
  "name" => "",
  "sub" => {}
}
tree_root.glob('**/*').each { |p|
  next if not p.file?
  next if p.to_s.end_with? '.meta.json'
  rel_path = p.relative_path_from tree_root
  cur_trie = trie
  path_comps = rel_path.to_s.split('/')
  path_comps.each_with_index { |cur, idx|
    if idx + 1 == path_comps.size
      meta = {
        "date": "???? ?? ??"
      }
      meta_path = p.sub_ext('.meta.json')
      if meta_path.exist?
        meta = JSON.parse(meta_path.read())
      end
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
