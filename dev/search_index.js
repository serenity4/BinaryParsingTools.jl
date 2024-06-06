var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = BinaryParsingTools","category":"page"},{"location":"#BinaryParsingTools","page":"Home","title":"BinaryParsingTools","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for BinaryParsingTools.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [BinaryParsingTools]","category":"page"},{"location":"#BinaryParsingTools.Tag","page":"Home","title":"BinaryParsingTools.Tag","text":"N-string tag.\n\n\n\n\n\n","category":"type"},{"location":"#BinaryParsingTools.cache_stream_in_ram","page":"Home","title":"BinaryParsingTools.cache_stream_in_ram","text":"cache_stream_in_ram(io::IO, ::Type{T})\n\nDetermine whether to cache the full IOStream in RAM or not to increase performance, using an IOBuffer.\n\nDefaults to true. This is advised for small-ish files, because access will be much easier if only a single IO access is required (one for reading the whole binary blob). On the other hand, that will increase RAM consumption, and dramatically so for large files.\n\n\n\n\n\n","category":"function"},{"location":"#BinaryParsingTools.read_at-Tuple{IO, Any, Any, Vararg{Any}}","page":"Home","title":"BinaryParsingTools.read_at","text":"Read a value of type T located at an offset from a given start (defaulting to the current position), without modifying the stream position.\n\n\n\n\n\n","category":"method"},{"location":"#BinaryParsingTools.swap_endianness","page":"Home","title":"BinaryParsingTools.swap_endianness","text":"swap_endianness(io::IO, ::Type{T})\n\nDecide whether to swap the endianness on any data read from the provided IO (defaults to false if not extended).\n\nIf the binary format being used chooses a specific endianness, you may extend this function for the related type you are trying to parse and decide depending on host endianness.\n\nFor example, assuming the data is in little-endian (1) or big-endian (2) format:\n\n# The host is in little-endian format if `ENDIAN_BOM == 0x04030201` (see the documentation for `Base.ENDIAN_BOM`).\n# If that is the case then assuming binary data is expected in little-endian format there is no need to swap the endianness.\nswap_endianness(io::IO, ::Type{BinaryData}) = ENDIAN_BOM == 0x01020304 # data comes in as little-endian, host is big-endian\n\n# That will be the opposite if the binary data format is expected in big-endian; little-endian machines\n# will need to swap the endianness.\nswap_endianness(io::IO, ::Type{BinaryData}) = ENDIAN_BOM == 0x04030201 # data comes in as big-endian, host is little-endian\n\nIf you don't know in which endianness the data comes, you would typically parse a magic number to determine whether endianness differs from the host:\n\nswap_endianness(io::IO, ::Type{BinaryData}) = read(io, UInt32) == 0x87654321 # expecting 0x12345678 as magic number\n\n\n\n\n\n","category":"function"},{"location":"#BinaryParsingTools.@serializable-Tuple{Any}","page":"Home","title":"BinaryParsingTools.@serializable","text":"Mark a given struct as serializable, automatically implementing Base.read.\n\nIf some of the structure members are vectors, their length must be specified using a syntax of the form params::Vector{UInt32} => param_count where param_count can be any expression, which may depend on other structure members.\n\nFields can be read in a custom manner by using a syntax of the form params::SomeField << ex where ex can be e.g. read(io, SomeField, other_field.length) where other_field can refer to any previous field in the struct. This expression may refer to a special variable __origin__, which is the position of the IO before parsing the struct.\n\nAdditional arguments required for Base.read can be specified with the syntax @arg name at the very start of the structure, before any actual fields. In this way, the definition for Base.read will include these extra arguments. Calling code will then have to provide these extra arguments.\n\nLineNumberNodes will be preserved and inserted wherever necessary to keep stack traces informative.\n\nExamples\n\n@serializable struct MarkArrayTable\n  mark_count::UInt16\n  mark_records::Vector{MarkRecord} => mark_count\nend\n\n@serializable struct LigatureAttachTable\n  @arg mark_class_count # will need to be provided when `Base.read`ing this type.\n\n  # Length of `component_records`.\n  component_count::UInt16\n\n  component_records::Vector{Vector{UInt16}} << [[read(io, UInt16) for _ in 1:mark_class_count] for _ in 1:component_count]\nend\n\nHere is an advanced example which makes use of all the features:\n\n@serializable struct LigatureArrayTable\n  @arg mark_class_count # will need to be provided when `Base.read`ing this type.\n\n  # Length of `ligature_attach_offsets`.\n  ligature_count::UInt16\n\n  # Offsets in bytes from the origin of the structure to data blocks formatted as `LigatureAttachTable`s.\n  ligature_attach_offsets::Vector{UInt16} => ligature_count\n\n  ligature_attach_tables::Vector{LigatureAttachTable} << [read_at(io, LigatureAttachTable, offset, mark_class_count; start = __origin__) for offset in ligature_attach_offsets]\nend\n\n\n\n\n\n","category":"macro"}]
}
