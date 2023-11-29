---
layout: post
title:  "Which methods an Any type should have?"
categories: design
---

Here under `Any` is object-root hierarchy meant

## Why there should be no `hashCode`, `equals` in `Any` and `Comparable` as a type

This methods look like a Java legacy, as they prohibit modifications, that make collections work different for different types. For instance, `Map` can be implemented via `Set`, if pair comparator compares only first elements (same with `hashCode` and `equals`). Instead of all this methods, their users must accept a `Comparator` and so on, where there may be a "default" that does language-specific things

## Why there should be no `equals`?
`equals` semantics may be different:
- It may compare pointers
- It may compare values
- It may compare values is special way (-0 != +0)

There is also an issue with "compare pointers", as single dispatch can't correctly handle all `null`/`undefined` cases

## Should there be a `toString`?
Well, there are two issues with `toString`:
-  I am pretty sure that default `toString` signature is incorrect. Why is it `this.toString(): String` and not `this.toString(sb: StringBuilder): void`? First variant has extremely degraded performance, while second variant allows just making a stub
- Why is it called `toString`? It should be called `toDebugString`. And should it be possible to override such method? That is probably a philosophical question, I would tend to answer "no", but who knows.

## Proposed `Any` type

{% highlight pseudo-ts %}
class Any {
  final toDebugString(): String {
    let sb = new StringBuilder()
    this.toDebugString(sb)
    return sb.getString()
  }

  open toDebugString(sb: StringBuilder): Unit {
    Runtime.dump(this, sb)
  }
}

namespace Runtime {
  function isSameReference(l: Any, r: Any): Boolean
  function getSystemHashCode(a: Any): USize
}
{% endhighlight %}
