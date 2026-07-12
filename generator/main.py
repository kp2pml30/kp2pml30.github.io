#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
from argparse import ArgumentParser, Namespace
from collections import Counter
from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass, field
from datetime import datetime
from email.utils import format_datetime
from html import escape
from html.parser import HTMLParser
from pathlib import Path
from threading import Lock
from typing import Any

from wordcloud import WordCloud

SITE_ROOT = Path(
	os.environ.get('KP2PML30_SITE_ROOT', Path(__file__).resolve().parent.parent)
)
FRONTEND_ROOT = (
	SITE_ROOT / 'frontend' if (SITE_ROOT / 'frontend').is_dir() else SITE_ROOT
)
TREE_ROOT = FRONTEND_ROOT / 'public' / 'fs-tree'
SITE_URL = 'https://kp2pml30.moe'
UNKNOWN_DATE = '???? ?? ??'
OUTPUT_LOCK = Lock()
WORD_RE = re.compile(r"[A-Za-z][A-Za-z0-9_'-]{2,}")
IGNORED_TEXT_TAGS = {'code', 'head', 'math', 'pre', 'script', 'style', 'svg'}
STOP_WORDS = {
	'about',
	'after',
	'all',
	'also',
	'and',
	'are',
	'but',
	'can',
	"can't",
	'could',
	"couldn't",
	'do',
	"don't",
	'does',
	"doesn't",
	'for',
	'from',
	'have',
	'here',
	'into',
	'its',
	'just',
	'like',
	'more',
	'not',
	'one',
	'only',
	'our',
	'out',
	'should',
	'some',
	'than',
	'that',
	'the',
	'their',
	'there',
	'these',
	'they',
	'this',
	'was',
	'when',
	'which',
	'while',
	'will',
	'with',
	'would',
	'you',
	'your',
	"i'll",
}
AURA_WORD_COLORS = (
	'#a277ff',
	'#61ffca',
	'#ffca85',
	'#f694ff',
	'#82e2ff',
	'#ff6767',
	'#edecee',
)


def default_meta() -> dict[str, Any]:
	return {
		'date': UNKNOWN_DATE,
		'date_created': UNKNOWN_DATE,
		'date_edited': UNKNOWN_DATE,
		'tags': [],
	}


@dataclass
class BlogItem:
	title: str
	date: str
	date_edited: str | None
	path: str


@dataclass
class Options:
	check_ignored: bool
	jobs: int


@dataclass
class ProcessedFile:
	path: Path
	meta: dict[str, Any]
	parser: HtmlMetadataParser | None
	words: Counter[str] = field(default_factory=Counter)


@dataclass
class HtmlMetadataParser(HTMLParser):
	meta: dict[str, Any] = field(default_factory=default_meta)
	first_h1: str | None = None
	words: Counter[str] = field(default_factory=Counter)
	_in_h1: bool = False
	_h1_parts: list[str] = field(default_factory=list)
	_ignored_depth: int = 0

	def __post_init__(self) -> None:
		super().__init__()

	def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
		if tag in IGNORED_TEXT_TAGS:
			self._ignored_depth += 1

		attrs_dict = dict(attrs)
		if tag == 'meta':
			name = attrs_dict.get('name')
			content = attrs_dict.get('content')
			if content is None:
				return
			if name in {'date', 'date-created', 'date-edited'}:
				self.meta[name.replace('-', '_')] = content
			elif name == 'tags':
				self.meta['tags'] = [tag.strip() for tag in content.split(',') if tag.strip()]
		elif tag == 'h1' and self.first_h1 is None:
			self._in_h1 = True
			self._h1_parts = []

	def handle_endtag(self, tag: str) -> None:
		if tag in IGNORED_TEXT_TAGS and self._ignored_depth:
			self._ignored_depth -= 1
		if tag == 'h1' and self._in_h1:
			self.first_h1 = ''.join(self._h1_parts).strip()
			self._in_h1 = False

	def handle_data(self, data: str) -> None:
		if self._in_h1:
			self._h1_parts.append(data)
		if self._ignored_depth:
			return
		for match in WORD_RE.finditer(data.lower()):
			word = match.group(0).strip("'_-")
			if word and word not in STOP_WORDS:
				self.words[word] += 1


def parse_args() -> Options:
	parser = ArgumentParser()
	parser.add_argument(
		'--check-ignored',
		action='store_true',
		help='warn when a generated target is not matched by gitignore',
	)
	parser.add_argument(
		'-j',
		'--jobs',
		type=int,
		default=os.cpu_count() or 1,
		help='number of files to process concurrently',
	)
	args: Namespace = parser.parse_args()
	if args.jobs < 1:
		parser.error('--jobs must be at least 1')
	return Options(check_ignored=args.check_ignored, jobs=args.jobs)


def warn_if_not_gitignored(path: Path) -> None:
	result = subprocess.run(
		['git', 'check-ignore', '--quiet', '--no-index', '--', str(path)],
		cwd=SITE_ROOT,
		check=False,
	)
	if result.returncode == 0:
		return

	try:
		display_path = path.relative_to(SITE_ROOT)
	except ValueError:
		display_path = path
	with OUTPUT_LOCK:
		print(
			f'warning: generated target is not gitignored: {display_path}',
			file=sys.stderr,
		)


def write_generated_text(path: Path, text: str, options: Options) -> None:
	if options.check_ignored:
		warn_if_not_gitignored(path)
	path.write_text(text)


def render_blog(path: Path, options: Options) -> None:
	target = path.with_suffix('')
	if options.check_ignored:
		warn_if_not_gitignored(target)

	# The renderer is the Racket yamd CLI, provided on PATH by the flake input
	# (git.kp2pml30.moe/ya/yamd). It takes the input file positionally and
	# writes an HTML fragment to -o (html is the default backend). Override the
	# binary with the YAMD env var, e.g. YAMD='nix run .#yamd --'.
	args = [
		*shlex.split(os.environ.get('YAMD', 'yamd')),
		str(path),
		'-o',
		str(target),
	]
	# Project-local yamd plugins live as collections under frontend/yamd-lib
	# (e.g. #use(jp/furigana) -> frontend/yamd-lib/jp/furigana.rkt). Put that
	# dir on Racket's collection search path; the leading colon preserves
	# Racket's defaults and the yamd CLI's own collection.
	env = os.environ.copy()
	plugins = (FRONTEND_ROOT / 'yamd-lib').resolve()
	env['PLTCOLLECTS'] = f':{plugins}'
	result = subprocess.run(
		args,
		env=env,
		text=True,
		capture_output=True,
		check=False,
	)
	if result.returncode != 0:
		msg = f'run failed {result.stdout} {result.stderr} {args}'
		raise RuntimeError(msg)

	with OUTPUT_LOCK:
		print(f'{path} -> {target}')
		if result.stdout:
			print(f'=== stdout ===\n{result.stdout}')
		if result.stderr:
			print(f'=== stderr ===\n{result.stderr}')


def process_yamd(
	path: Path, options: Options
) -> tuple[Path, dict[str, Any], HtmlMetadataParser | None]:
	render_blog(path, options)
	generated = path.with_suffix('')
	meta = default_meta()
	parser = None
	if generated.exists():
		parser = HtmlMetadataParser(meta=meta)
		parser.feed(generated.read_text())
	return generated, meta, parser


def parse_html_file(path: Path) -> HtmlMetadataParser | None:
	if path.suffix not in {'.blog', '.html'}:
		return None

	parser = HtmlMetadataParser()
	parser.feed(path.read_text())
	return parser


def process_file(path: Path, options: Options) -> ProcessedFile:
	if str(path).endswith('.yamd'):
		path, meta, parser = process_yamd(path, options)
		return ProcessedFile(
			path=path,
			meta=meta,
			parser=parser,
			words=parser.words if parser else Counter(),
		)

	meta = default_meta()
	meta_path = path.with_suffix('.meta.json')
	if meta_path.exists():
		meta = json.loads(meta_path.read_text())
	parser = parse_html_file(path)
	return ProcessedFile(
		path=path,
		meta=meta,
		parser=parser,
		words=parser.words if parser else Counter(),
	)


def insert_file(trie: dict[str, Any], path: Path, meta: dict[str, Any]) -> None:
	rel_path = path.relative_to(TREE_ROOT)
	cur_trie = trie
	parts = rel_path.parts
	for idx, cur in enumerate(parts):
		if idx + 1 == len(parts):
			cur_trie['sub'][cur] = {
				'kind': 'file',
				'name': cur,
				'meta': meta,
			}
			continue
		if cur not in cur_trie['sub']:
			cur_trie['sub'][cur] = {
				'kind': 'dir',
				'name': cur,
				'sub': {},
			}
		cur_trie = cur_trie['sub'][cur]


def normalize_tree(value: dict[str, Any]) -> dict[str, Any]:
	if value['kind'] == 'dir':
		value['sub'] = [normalize_tree(child) for child in value['sub'].values()]
		value['sub'].sort(key=lambda child: (child['kind'], child['name']))
	return value


def xml_text(name: str, text: str) -> str:
	return f'<{name}>{escape(text, quote=False)}</{name}>'


def format_pub_date(value: str) -> str:
	year, month, day = (int(part) for part in value.split(' '))
	date = datetime(year, month, day).astimezone()
	return format_datetime(date)


def build_feed(blog_items: list[BlogItem]) -> str:
	items = []
	for item in blog_items:
		body = [
			xml_text('title', item.title),
			xml_text('link', f'{SITE_URL}/view/{item.path}'),
		]
		if item.date != UNKNOWN_DATE:
			body.append(xml_text('pubDate', format_pub_date(item.date)))
		items.append(f'<item>{"".join(body)}</item>')

	channel = ''.join(
		[
			xml_text('title', 'kp2pml30.moe'),
			xml_text('link', SITE_URL),
			xml_text('description', "kp2pml30's blog"),
			*items,
		]
	)
	return (
		'<?xml version="1.0" encoding="UTF-8"?>'
		f'<rss version="2.0"><channel>{channel}</channel></rss>'
	)


def build_sitemap(blog_items: list[BlogItem]) -> str:
	urls = [
		f'<url>{xml_text("loc", f"{SITE_URL}{path}")}</url>'
		for path in ['/', '/about', '/fs', '/lnk']
	]
	for item in blog_items:
		body = [xml_text('loc', f'{SITE_URL}/view/{item.path}')]
		lastmod = item.date_edited or item.date
		if lastmod != UNKNOWN_DATE:
			body.append(xml_text('lastmod', lastmod.replace(' ', '-')))
		urls.append(f'<url>{"".join(body)}</url>')

	return (
		'<?xml version="1.0" encoding="UTF-8"?>'
		'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
		f'{"".join(urls)}</urlset>'
	)


def aura_word_color(word: str, *args: Any, **kwargs: Any) -> str:
	return AURA_WORD_COLORS[sum(ord(char) for char in word) % len(AURA_WORD_COLORS)]


def write_tag_cloud(words: Counter[str], path: Path, options: Options) -> None:
	if not words:
		path.unlink(missing_ok=True)
		return
	if options.check_ignored:
		warn_if_not_gitignored(path)

	bad_words = [x for x in words if "'" in x or '"' in x]
	bad_words.extend(['kp2pml30', 'r3vdy', 'b10vv', 'r3vdy-2-b10vv'])

	cloud_words = words.copy()
	for word in bad_words:
		del cloud_words[word]

	if not cloud_words:
		path.unlink(missing_ok=True)
		return

	cloud = WordCloud(
		width=1200,
		height=630,
		background_color=None,
		mode='RGBA',
		color_func=aura_word_color,
		prefer_horizontal=0.8,
		random_state=0,
	).generate_from_frequencies(cloud_words)
	path.write_text(cloud.to_svg(embed_font=True))

	with OUTPUT_LOCK:
		print(f'word cloud written to {path}')


def process_paths(paths: list[Path], options: Options) -> list[ProcessedFile]:
	if len(paths) <= 1:
		return [process_file(path, options) for path in paths]

	with ThreadPoolExecutor(max_workers=min(options.jobs, len(paths))) as executor:
		futures: list[Future[ProcessedFile]] = [
			executor.submit(process_file, path, options) for path in paths
		]
		return [future.result() for future in futures]


def main() -> None:
	options = parse_args()
	trie = {
		'kind': 'dir',
		'name': '',
		'sub': {},
	}
	blog_items: list[BlogItem] = []
	tags: Counter[str] = Counter()
	words: Counter[str] = Counter()
	paths = []

	for path in sorted(TREE_ROOT.glob('**/*')):
		if not path.is_file():
			continue
		if str(path).endswith('.meta.json'):
			continue
		if Path(f'{path}.yamd').exists():
			continue
		paths.append(path)

	for processed in process_paths(paths, options):
		path = processed.path
		meta = processed.meta
		parser = processed.parser

		if str(path).endswith('.blog') and parser is not None:
			if meta['date'] is None:
				msg = f'No date found for {path} {meta}'
				raise RuntimeError(msg)
			blog_items.append(
				BlogItem(
					title=parser.first_h1 or path.name,
					date=meta['date'],
					date_edited=meta['date_edited'],
					path=path.relative_to(TREE_ROOT).as_posix(),
				)
			)

		words.update(processed.words)
		tags.update(meta.get('tags', []))
		insert_file(trie, path, meta)

	trie = normalize_tree(trie)
	write_generated_text(
		FRONTEND_ROOT / 'src' / 'tree.json',
		json.dumps(trie, separators=(',', ':')),
		options,
	)

	blog_items = list(
		reversed(
			sorted(
				blog_items,
				key=lambda item: (
					1 if item.date == UNKNOWN_DATE else 0,
					'' if item.date == UNKNOWN_DATE else item.date,
				),
			)
		)
	)

	generated_dir = FRONTEND_ROOT / 'public' / 'a' / 'generated'
	write_generated_text(generated_dir / 'feed.xml', build_feed(blog_items), options)
	write_generated_text(
		generated_dir / 'sitemap.xml', build_sitemap(blog_items), options
	)

	word_cloud_path = generated_dir / 'word-cloud.svg'
	word_cloud_path.unlink(missing_ok=True)
	write_tag_cloud(words, word_cloud_path, options)
	tag_cloud_path = generated_dir / 'tag-cloud.svg'
	tag_cloud_path.unlink(missing_ok=True)
	write_tag_cloud(tags, tag_cloud_path, options)


if __name__ == '__main__':
	main()
