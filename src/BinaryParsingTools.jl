module BinaryParsingTools

using SwapStreams: SwapStream
using Mmap
using .Meta: isexpr

"""
    swap_endianness(io::IO, ::Type{T})

Decide whether to swap the endianness on any data read from the provided IO (defaults to `false` if not extended).

If the binary format being used chooses a specific endianness, you may extend this function
for the related type you are trying to parse and decide depending on host endianness.

For example, assuming the data is in little-endian (1) or big-endian (2) format:
```julia
# The host is in little-endian format if `ENDIAN_BOM == 0x04030201` (see the documentation for `Base.ENDIAN_BOM`).
# If that is the case then assuming binary data is expected in little-endian format there is no need to swap the endianness.
swap_endianness(io::IO, ::Type{BinaryData}) = ENDIAN_BOM == 0x01020304 # data comes in as little-endian, host is big-endian

# That will be the opposite if the binary data format is expected in big-endian; little-endian machines
# will need to swap the endianness.
swap_endianness(io::IO, ::Type{BinaryData}) = ENDIAN_BOM == 0x04030201 # data comes in as big-endian, host is little-endian
```

If you don't know in which endianness the data comes, you would typically parse a magic number to determine whether
endianness differs from the host:
```julia
swap_endianness(io::IO, ::Type{BinaryData}) = read(io, UInt32) == 0x87654321 # expecting 0x12345678 as magic number
```
"""
function swap_endianness end

swap_endianness(io::IO, ::Type{T}) where {T} = false

"""
    cache_stream_in_ram(io::IO, ::Type{T})

Determine whether to cache the full IOStream in RAM or not to increase performance, using an `IOBuffer`.

Defaults to false. Turning it on is advised for small-ish files that will be used in their entirety, because access will be much easier if only a single IO access is
required (one for reading the whole binary blob). On the other hand, that will increase RAM consumption,
and dramatically so for large files.
"""
function cache_stream_in_ram end

cache_stream_in_ram(io::IO, ::Type{T}) where {T} = false

"""
    use_memory_mapping(io::IO, ::Type{T})

Determine whether to memory-map the IO.

This may result in faster accesses and improved memory usage, especially for large files.
"""
function use_memory_mapping end

# Broken on 1.12 nightly, see https://github.com/JuliaLang/julia/issues/54128
use_memory_mapping(io::IO, ::Type{T}) where {T} = false

const BinaryIO = SwapStream

function read_binary(io::IO, ::Type{T}; kwargs...) where {T}
  if use_memory_mapping(io, T)
    bytes = mmap(io)
    io = cache_stream_in_ram(io, T) ? IOBuffer(copy(bytes)) : IOBuffer(bytes)
  elseif cache_stream_in_ram(io, T)
    io = IOBuffer(read(io))
  end
  io = BinaryIO(swap_endianness(io, T), io)
  read(io, T; kwargs...)
end

"""
Read a value of type `T` located at an offset from a given start (defaulting
to the current position), without modifying the stream position.
"""
function read_at(io::IO, @nospecialize(T), offset, args...; start = position(io))
  pos = position(io)
  seek(io, start + offset)
  val = read(io, T, args...)
  seek(io, pos)
  val
end

function read_null_terminated_string(io::IO)
  bytes = UInt8[]
  next = read(io, UInt8)
  while next ≠ 0x00
    push!(bytes, next)
    next = read(io, UInt8)
  end
  String(bytes)
end

include("serializable.jl")
include("tag.jl")

export @serializable,
       read_binary, BinaryIO,
       read_at, read_null_terminated_string,
       Tag, Tag2, Tag3, Tag4,
       @tag_str, @tag2_str, @tag3_str, @tag4_str

# XXX: seems to crash CSTParser for VSCode linting
# public swap_endianness, cache_stream_in_ram

end
