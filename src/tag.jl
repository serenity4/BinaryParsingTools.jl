"N-string tag."
struct Tag{N}
  data::NTuple{N, UInt8}
end

function Tag{N}(str::AbstractString) where {N}
  chars = collect(str)
  length(chars) == N || error("Expected $N-character string for tag, got string \"$str\" with length $(length(chars)).")
  for c in chars
    isascii(c) || error("Tags must be ASCII strings, got non-ASCII character '$c' for \"$str\".")
  end
  Tag(ntuple(i -> UInt8(chars[i]), N))
end

Tag(str::AbstractString) = Tag{length(str)}(str)

const Tag2 = Tag{2}
const Tag3 = Tag{3}
const Tag4 = Tag{4}

Base.uppercase(tag::Tag) = Tag(UInt8.((uppercase.(Char.(tag.data)))))
Base.lowercase(tag::Tag) = Tag(UInt8.((lowercase.(Char.(tag.data)))))
Base.reverse(tag::Tag) = Tag(reverse(tag.data))

macro tag_str(str) Tag(str) end
macro tag2_str(str) Tag2(str) end
macro tag3_str(str) Tag3(str) end
macro tag4_str(str) Tag4(str) end

Base.read(io::IO, ::Type{Tag{N}}) where {N} = Tag{N}(ntuple(_ -> read(io, UInt8), N))
Base.show(io::IO, tag::Tag) = print(io, '"', join(Char.(tag.data)), '"')
Base.string(tag::Tag) = join(Char.(tag.data))
Base.convert(::Type{Tag}, str::AbstractString) = Tag(str)
Base.convert(::Type{Tag{N}}, str::AbstractString) where {N} = Tag{N}(str)
Base.isless(x::Tag, y::Tag) = isless(string(x), string(y))
function Base.write(io::IO, tag::Tag)
  nb = 0
  for char in tag.data
    nb += write(io, char)
  end
  nb
end
