---
layout: post
title:  "Issue with Programming Language Compilers Backends"
categories: design interoperability yadk
---

Implementation of a programming language is a somewhat solved problem: there are multiple backends that a higher-language compiler can target, including JVM, .NET, LLVM and Graal VM, however language interoperability is an unsolved problem.

## Overview

"Native" languages mostly interop via FFI and C compatible ABI. Some languages require manual writing of bindings (i.e. Java), while others provide more sophisticated ways:
- Python has a library called cppyy, which utilizes clang (and cling) to parse C++ header files and expose bindings into python. Calls to imported functions may be slower than to python ones due to primitives re-boxing and so on
- LuaJIT also parses C headers, but it has a JIT compiler that can optimize calls to native functions, and replace field accesses with primitive mov/ldr. However, this interoperability is single directed, as C code can't access Lua objects (tables)
- Zig language facilitates clang to transform C source files into Zig AST, and again passing Zig constructs into C requires marking them as external

<br />"Managed" languages interoperability is complicated by garbage collection. If both languages are compiled into single bytecode (i.e. to JVM or .NET CIL), then there is a possibility to communicate (as does Scala, Java and Kotlin). However, some languages can't be efficiently compiled into this bytecodes. For instance, Nashorn does and attempt of compiling ecmascript into JVM bytecode, but its execution speed is not that fascinating.

Other approach, used by GraalVM is meta circular VMs. It utilizes JVMCI and OpenJDK JIT to transform AST nodes into packed compiled code which can also utilize profile. However, this approach may be not suitable in browsers on low-end mobile devices, where slow interpretation of AST, as well as its memory footprint is unacceptable

## Possible solution
It might be possible to create a VM, where all instructions are iteratively lowered, which will allow for most of the language-specific optimizations, but will also unsure semantics some base instructions. For instance, all calls may be performed via something similar to [`invoke.dynamic`](https://www.baeldung.com/java-invoke-dynamic). There would be a single "invoke" method, that will invoke language-specific function, which itself will resolve overloads. So, if part of the compiler is inlined into this process, than language can decide what to do with a method and arguments, knowing exact types of provided argument at compile time.

Example:
{% highlight pseudo-ts %}
interface I {
  foo(): Unit
}

class C implements I {
  override foo(): Unit {}
}

new C().foo()
# ^ this line may be lowered into
# lang/invoke/I.foo
# where lang/invoke/I/foo is implemented like this:
fn lang/invoke/I/foo(this): Unit {
  return this.vtable.at(0).invoke(this)
}
{% endhighlight %}

This approach adds complexity of single call (which may be inlined and dispatched-at place), but allows implementing [all common types of generics]({% post_url 2023-11-28-generics-implementations %}), if stencil'er is bundled with compiler. Invoking a compiler in compiler, what can be cooler?

## Further considerations

There are, however, some isses that are still hard to address. They include stack-copying (used in Go & Erlang/Elixir), coroutine-local GC (used in Erlang/Elixir). This features must be hardly incorporated into runtime to be supported. It must also be noted, that to bring interoperability to statically-typed languages they must be aware of some `Any` (foreign) type, which will have some base operations, and cause RTE if they are invoked in inappropriate manner. Probably some common type describing interface can be brought to support gradual typing in this place.
