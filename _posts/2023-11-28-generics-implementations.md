---
layout: post
title:  "Generics Implementations"
categories: design interoperability yadk
---

All generic implementations are described in [this blog](https://thume.ca/2019/07/14/a-tour-of-metaprogramming-models-for-generics/), however they can be grouped into less categories.

## Type-erased
All generics share same body and functions don't need monomorphization. It is the easiest case, as nearly nothing is needed from runtime (if we do not consider optimizations that actually do monomorphization).

## Shared with type information
Again, generics share same body, however some "generic dictionary" is passed to each generic function at call-site, which preserves type information, as it is done is C#.

## Full stenciling
All functions for different bodies are copied at some point, which forbids dynamic linking and instantiation of new versions in runtime in all known to me cases.

## Problem
If runtime wishes to support full interoperability, then runtime must be capable of supporting all of them at once and be able to switch between. Unfortunately, switching from type-erased generics to other can be done only via some `Any` type

## yadk

All generics should be accessed via getting functions, which may have language-specific implementations

```pseudots
# consider below function
fn foo<T>(t: T): void

# with type erasure
fn fooErased(t: Type) : FType {
    return fn (x: ManagedPtr LangObject): void {
    }
}

# with generic dictionaries
fn fooShared(t: Type) : FType {
    let val = LangRuntime.getGenericDictFor('foo', t)
    return fn (x: ManagedPtr Object): void {
        // use val
    }
}

# with generic dictionaries
fn fooStenciled(t: Type) : FType {
    return LangCompiler.getOrStencilFor('foo', t) # metadata should be stored
}
```
