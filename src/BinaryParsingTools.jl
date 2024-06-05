module BinaryParsingTools

using SwapStreams: SwapStream
using .Meta: isexpr

swap_endianness(io::IO, ::Type{T}) where {T} = false

function read_binary end

read(io::IOBuffer, ::Type{T}) where {T} = read_binary(SwapStream(swap_endianness(io, T), io), T)
read(io::IO, ::Type{T}) where {T} = read(IOBuffer(Base.read(io)), T)

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
       read_at,
       Tag, Tag2, Tag3, Tag4,
       @tag_str, @tag2_str, @tag3_str, @tag4_str

# XXX: seems to crash CSTParser for VSCode linting
# public read, swap_endianness, read_binary

end
