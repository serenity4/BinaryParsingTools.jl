using BinaryParsingTools
using Test
using Logging

@serializable struct TestData
  magic_number::UInt32
  name::Tag4
end

@serializable struct TestDataSwapped
  magic_number << read(io, UInt32)
  name::Tag4
end

@serializable struct TestPadded
  magic_number::UInt32
  @reserved 4 # 4 bytes
  name::Tag4
end

BinaryParsingTools.swap_endianness(::IO, ::Type{TestDataSwapped}) = true

@testset "BinaryParsingTools.jl" begin
  @testset "Tags" begin
    t = Tag("FRA ")
    @test isa(t, Tag4)
    @test convert(Tag, "FRA ") === t
    @test convert(Tag4, "FRA ") === t
    @test tag"FRA " === t
    @test tag"FRA" !== tag"FRA "
    @test isa(tag"FRA", Tag3)
    @test_throws "at most 4 string codeunits" Tag4("FRACCC")
    @test uppercase(tag"fr") === tag"FR"
    @test lowercase(tag"FR") === tag"fr"

    t = Tag("FRA\0")
    @test t == tag4"FRA"
    t3 = convert(Tag{3}, t)
    @test t3 === tag3"FRA"
    t4 = convert(Tag{4}, t3)
    @test t4 === t
    @test_throws "character for truncation" convert(Tag{2}, t)

    @test Tag("α") === tag2"α"
  end

  @testset "Parsing" begin
    data = open(io -> read(io, TestData), joinpath(@__DIR__, "test.bin"))
    @test data.magic_number === 0x00100000
    @test data.name === tag4"test"
    data = open(io -> read_binary(io, TestDataSwapped), joinpath(@__DIR__, "test.bin"))
    @test data.magic_number === 0x00001000
    io = IOBuffer()
    data = TestPadded(0x00100000, tag4"test")
    write(io, data.magic_number)
    write(io, 0x00000000)
    write(io, data.name)
    seekstart(io)
    @test read(io, TestPadded) == data
  end

  @testset "@serializable macro" begin
    with_logger(NullLogger()) do
      @test_throws "must be typed" @macroexpand @serializable struct SomeType
        a
        b
      end

      @test_throws "Vectors must have a corresponding length." @macroexpand @serializable struct SomeType
        count::UInt32
        vec::Vector{Float64}
      end
    end

    ex = @macroexpand @serializable struct SomeType
      count::UInt32
      vec::Vector{Float64} => count
    end
    sdef, fdef = ex.args[2:2:4]
    @test :(vec = [read(io, Float64) for _ = 1:count]) in fdef.args[2].args

    ex = @macroexpand @serializable struct ParametrizedType{T,S}
      values::NTuple{T,S}
    end
    @test isnothing(Base.eval(Module(), ex))
  end
end;
