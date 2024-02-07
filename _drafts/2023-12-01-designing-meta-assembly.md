---
layout: post
title:  "Designing Meta Assembly and Bytecode for yadk"
categories: design yadk
---

Such a language must conform following principles:
- Be as simple as possible
- Be extendable
- Be easily lexable and parsable

Which language comes to mind? Lisp! However, I personally dislike few features of Lisp
- Syntax
  - Absence of infix operators
  - Wrapping everything into `()`
  - Overly-complicated syntax for `if`
- Dynamic typing
- It may be less suitable for imperative languages

## Proposed syntax
- To be easily parsable
  - have only single-line comments
  - have semicolons `;`
- To support exotic identifiers, they may include nearly everything except for spaces and few special characters, such as `.;()`
- There should be a category of keywords that is rarely used, they must start with a special sign; this sign is proposed to be `#`, if not followed by a space or eol
- There should be a way to escape identifiers (`@"ident!"` in zig), proposed syntax also uses `#`. Less Symbols is better! (example: `#"fn"`)
- Use `{}` for blocks, make blocks mandatory after `if`/`while`, which allows to omit useless `()`, as it is done in golang
- Allow custom binary operators. This will allow to express potential array/map indexing as `(map ! key).* = 12`
  - allow operators with higher priority than call to allow following constructs:
    ```pseudots
    (foo -> method 1 2 3)
    ```
- Unfortunately, amount of arguments must be known at call site. It on the one hand forbids using Haskell's syntax (forces to use outer parenthesis), and on the other hand forbids Lisp style, as parenthesis may be used for binary operators. Another challenge is calling functions without arguments, as `(func)` is confusing in a language with binary operators and may complicate code-generation, as expressions can't be mindlessly wrapped into parenthesis, so I see few variants
    ```pseudots
    (foo I32) 31; # example of default syntax for calls
    # variants for no-args:
    noArgs ();
    noArgs !;
    noArgs #call;
    (noArgs)
    ```
    I like `noArgs ()` the most, as functions without arguments must be mostly avoided
- Dereferencing should have same syntax as member access, so I propose `ptr.*`, as in Zig
- Variables must be assigned with two keywords: `let` and `var`, as `val` is an extremely appealing word to use for a name, and `const` has different amount of letters =)

## Types
Unfortunately, for efficient compilation types must be known (or propagated via SSA)

Firstly, let's reuse `()` for a `void` type, then add primitive types for signed/unsigned/floating types with naming as in Zig but with capital first letter (i.e. `I32`)

For functions it seems easy on the first glance:
```pseudo-ts
fn putChar(f : Ptr File ; c : U32) : ()
# everything seems ok
# but what to do with dependent types?
# Example:
fn dependent(x : Type) : dependsOn x
```

How to dump this signature into a "bytecode" file? Well, let's see how languages use such functions

#### C++ templates/Zig compound functions
```cpp
template<int a>
/* something */
```
Here can be either
- Function
- Type
- Variable

And that is known from AST. However, variable type can only be erased (and returned as a pointer).

#### Idris
```idris
record Config where
    constructor MkConfig
    someType : Type

data Dep : Config -> Type where
    DepA :
        {conf : Config} ->
        conf.someType ->
        Dep conf
```

What do we have here?
- `Dep` "group" of types, and `Dep` has return type of a `Type`
- We have
  ```pseudo-ts
  fn DepA (conf : Config ; e1 : conf.someType) : Dep conf
  ```
Which is problematic, as we have a dependent return type (dependent argument can be changed into dependent return via currying). But we know that it is `Dep.DepA` instance. It brings me to a conclusion, that `Dep.DepA` must be expressed via erased generics, so return type is actually union `{ DepA : Config IdrisAny }`

#### yasm
There such entities as `Ptr : Type -> Type`, `alloca : (t : Type) -> Ptr t`. Probably we can just add `AnyPtr` and cast it, but what is a type of `cast`? It is `AnyPtr -> (t : Type) -> Ptr t`, which is again not expressable.

<br />

As such, all used by other languages variants can be expressed, except for `alloca` and related

## How to express a dependent type?
I see few options:
- Introduce annotated types, that have both erased type and relevant type information
- Add interpreter to a compiler
- Type check in a vm (bad thing to do)

## Finally, what VM needs?
- First class functions
- First class types

Having first class function is a bit problematic, as they should have captures
