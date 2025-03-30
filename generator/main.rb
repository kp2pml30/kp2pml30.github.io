#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'json'
require 'open3'

root = Pathname.new(__FILE__).parent.parent
tree_root = root.join('frontend', 'public', 'fs-tree')
trie = {
	"kind" => "dir",
	"name" => "",
	"sub" => {}
}

def render_blog(path)
	target = path.sub_ext('')

	yamd = Pathname.new(__FILE__).parent.join('yamd', 'exe', 'yamd')
	gem = Pathname.new(__FILE__).parent.join('yamd', 'Gemfile')
	args = 'bundle', 'exec', "--gemfile=#{gem.to_s}", yamd.to_s, '--in', path.to_s, '--out', target.to_s
	o, e, s = Open3.capture3(*args)
	raise "run failed #{o} #{e} #{args}" if not s.success?

	puts path
end

tree_root.glob('**/*').each { |p|
	next if not p.file?
	next if p.to_s.end_with? '.meta.json'
	next if p.to_s.end_with? '.blog'
	meta = {
		"date": "???? ?? ??"
	}
	if p.to_s.end_with? '.yamd'
		render_blog(p)
		p = p.sub_ext('')
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
