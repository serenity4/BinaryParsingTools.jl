module BinaryParsingTools

using SwapStreams: SwapStream
using .Meta: isexpr

"""
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

const BinaryIO = SwapStream

read_binary(io::IOBuffer, ::Type{T}; kwargs...) where {T} = read(SwapStream(swap_endianness(io, T), io), T; kwargs...)
read_binary(io::IO, ::Type{T}; kwargs...) where {T} = read_binary(IOBuffer(read(io)), T; kwargs...)

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

include("serializable.jl")
include("tag.jl")

export @serializable,
       read_binary, BinaryIO, read_at,
       Tag, Tag2, Tag3, Tag4,
       @tag_str, @tag2_str, @tag3_str, @tag4_str

# XXX: seems to crash CSTParser for VSCode linting
# public swap_endianness

end
