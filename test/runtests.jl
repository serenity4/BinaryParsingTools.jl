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
    @test_throws "4-character" Tag4("FRA")
    @test_throws "ASCII" Tag("FRAα")
    @test uppercase(tag"fr") === tag"FR"
    @test lowercase(tag"FR") === tag"fr"
  end

  @testset "Parsing" begin
    data = open(io -> read(io, TestData), joinpath(@__DIR__, "test.bin"))
    @test data.magic_number === 0x00100000
    @test data.name === tag4"test"
    data = open(io -> read_binary(io, TestDataSwapped), joinpath(@__DIR__, "test.bin"))
    @test data.magic_number === 0x00001000
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
