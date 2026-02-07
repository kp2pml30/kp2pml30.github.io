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

def default_meta
	{ date: "???? ?? ??" }
end

def render_blog(path)
	target = path.sub_ext('')

	yamd = Pathname.new(__FILE__).parent.join('yamd', 'exe', 'yamd')
	gem = Pathname.new(__FILE__).parent.join('yamd', 'Gemfile')
	args = 'bundle', 'exec', "--gemfile=#{gem.to_s}", yamd.to_s, '--in', path.to_s, '--out', target.to_s
	o, e, s = Open3.capture3(*args)
	raise "run failed #{o} #{e} #{args}" if not s.success?

	puts path
end

require 'nokogiri'
require 'builder'
require 'time'

rss = Builder::XmlMarkup.new(:indent => nil)
blog_items = []

def process_yamd(path)
	render_blog(path)
	generated = path.sub_ext('')
	meta = default_meta
	doc = nil
	if generated.exist?
		doc = Nokogiri::HTML.parse(generated.read())
		meta_tag = doc.at('meta[name="date"]')
		if meta_tag
			meta[:date] = meta_tag['content']
		end
	end
	return generated, meta, doc
end

tree_root.glob('**/*').each { |p|
	next if not p.file?
	next if p.to_s.end_with? '.meta.json'
	next if Pathname.new(p.to_s + '.yamd').exist?
	if p.to_s.end_with? '.yamd'
		p, meta, doc = process_yamd(p)
		if p.to_s.end_with?('.blog') && doc
			title_tag = doc.at('h1')
			raise "No date found for #{p} #{meta}" if meta[:date].nil?
			blog_items << {
				title: title_tag ? title_tag.text.strip : p.basename.to_s,
				date: meta[:date],
				path: p.relative_path_from(tree_root).to_s,
			}
		end
	else
		meta = default_meta
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

root.join('frontend', 'src', 'tree.json').write(JSON.dump(trie))

site_url = 'https://kp2pml30.moe'
blog_items.sort_by! { |item| item[:date] }.reverse!

rss.instruct! :xml, version: "1.0", encoding: "UTF-8"
rss.rss(version: "2.0") {
	rss.channel {
		rss.title "kp2pml30.moe"
		rss.link site_url
		rss.description "kp2pml30's blog"
		blog_items.each { |item|
			rss.item {
				rss.title item[:title]
				rss.link "#{site_url}/view/#{item[:path]}"
				if item[:date] != "???? ?? ??"
					parts = item[:date].split(' ')
					time = Time.new(parts[0].to_i, parts[1].to_i, parts[2].to_i)
					rss.pubDate time.rfc822
				end
			}
		}
	}
}

root.join('frontend', 'public', 'a', 'generated', 'feed.xml').write(rss.target!)

sitemap = Builder::XmlMarkup.new(:indent => nil)
sitemap.instruct! :xml, version: "1.0", encoding: "UTF-8"
sitemap.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") {
	%w[/ /about /fs /lnk].each { |path|
		sitemap.url { sitemap.loc "#{site_url}#{path}" }
	}
	blog_items.each { |item|
		sitemap.url {
			sitemap.loc "#{site_url}/view/#{item[:path]}"
			if item[:date] != "???? ?? ??"
				sitemap.lastmod item[:date].gsub(' ', '-')
			end
		}
	}
}

root.join('frontend', 'public', 'a', 'generated', 'sitemap.xml').write(sitemap.target!)
