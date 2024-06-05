# BinaryParsingTools

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://serenity4.github.io/BinaryParsingTools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://serenity4.github.io/BinaryParsingTools.jl/dev/)
[![Build Status](https://github.com/serenity4/BinaryParsingTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/serenity4/BinaryParsingTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/serenity4/BinaryParsingTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/serenity4/BinaryParsingTools.jl)

Provides a set of tools for working with binary data formats.

This library uses a `BinaryIO`, to be extended for any `Base.read` operations on
your types. Under the hood, this is an alias to `SwapStreams.SwapStream` which will
make sure you read in the correct endianness. To determine whether endianness should be changed, see `BinaryParsingTools.swap_endianness`.

Then, read any binary data using `read_binary` which will create the create the appropriate `BinaryIO` and dispatch to `Base.read(::BinaryIO, ::Type{MyType})`.

```julia
using BinaryParsingTools

BinaryParsingTools.swap_endianness(io::IO, ::Type{MyType}) = false

function Base.read(::BinaryIO, ::Type{MyType})
  # ...
end

open(io -> read_binary(io, MyType), "data.bin")
```

A `@serializable` macro is furthermore provided to automate the parsing of structs, as so:
```julia
@serializable struct MyType
  x::UInt32
  name::String << String([read(io, UInt8) for _ in 1:32])
end
```

which will automatically define `read(io::IO, ::Type{MyType})` (see the reference documentation for more details on how it works).
