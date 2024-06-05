using BinaryParsingTools
using Test

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
end;
