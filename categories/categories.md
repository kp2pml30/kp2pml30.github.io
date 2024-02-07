---
layout: page
title: Categories
permalink: /categories/
---

## Contents
{% assign categories = site.categories | sort -%}
{%- for category in categories -%}
- [{{ category[0] | escape }}](#{{ category[0] | escape }})
{% endfor -%}
{%- for category in categories %}
## \#{{ category[0] | escape }}
{% for post in site.posts -%}
{%- if post.categories contains category[0] -%}
- [{{ post.title | escape }}]({{ post.url | relative_url }})
{% endif -%}
{%- endfor -%}
{%- endfor -%}
