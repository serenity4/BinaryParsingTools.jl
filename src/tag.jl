"N-string tag."
struct Tag{N}
  data::NTuple{N, UInt8}
end

function Tag{N}(str::AbstractString) where {N}
  bytes = codeunits(str)
  length(bytes) ≤ N || error("Expected at most $N string codeunits for tag, got string \"$str\" with $(length(bytes)) codeunits.")
  Tag(ntuple(i -> get(bytes, i, 0x00), N))
end

Tag(str::AbstractString) = Tag{ncodeunits(str)}(str)

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
Base.show(io::IO, tag::Tag) = print(io, '"', string(tag), '"')
Base.string(tag::Tag) = String(collect(tag.data))
Base.convert(::Type{Tag}, str::AbstractString) = Tag(str)
Base.convert(::Type{Tag{N}}, str::AbstractString) where {N} = Tag{N}(str)
Base.isless(x::Tag, y::Tag) = isless(string(x), string(y))
function Base.write(io::IO, tag::Tag)
  nb = 0
  for byte in tag.data
    nb += write(io, byte)
  end
  nb
end

Tag4(data::UInt32) = Tag4(ntuple(i -> (data << 8(4 - i)) >> 24, 4))

function Base.convert(::Type{Tag{N2}}, tag::Tag{N1}) where {N1,N2}
  N1 === N2 && return tag
  N1 < N2 && return Tag{N2}(ntuple(i -> get(tag.data, i, 0x00), N2))
  for byte in tag.data[(N2 + 1):end]
    byte == 0x00 || byte == 0x20 #= space =# || error("Expected $(repr('\0')) or $(repr(' ')) character for truncation, got $(Char(byte))")
  end
  Tag{N2}(ntuple(i -> tag.data[i], N2))
end

(::Type{Tag{N2}})(tag::Tag{N1}) where {N1,N2} = convert(Tag{N2}, tag)
