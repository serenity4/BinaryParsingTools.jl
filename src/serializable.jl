function read_expr(field, linenum::LineNumberNode)
  if isexpr(field, :(::))
    T = field.args[2]
    isexpr(T, :curly) && T.args[1] == :Vector && error("Vectors must have a corresponding length.")
    isexpr(T, :curly) && T.args[1] == :NTuple && return :(ntuple(_ -> read(io, $(T.args[3])), $(T.args[2])))
    T == :String && error("Strings are not supported yet.")
    return :(read(io, $T))
  elseif isexpr(field, :call) && field.args[1] == :(=>)
    field, length = field.args[2:3]
    if isexpr(field, :(::))
      T = last(field.args)
      isexpr(T, :curly, 2) && T.args[1] == :Vector && return :([read(io, $(T.args[2])) for _ in 1:$length])
    end
  elseif isexpr(field, :call) && field.args[1] == :(<<)
    ex = field.args[3]
    # Add linenum info to comprehensions to make stack traces more readable.
    isexpr(ex, :comprehension) && (ex.args[1].args[1] = Expr(:block, linenum, ex.args[1].args[1]))
    return ex
  end
  error("Unexpected expression form: $field")
end

function serializable(ex, source::LineNumberNode)
  !isexpr(ex, :struct) && error("Expected a struct definition, got $(repr(ex))")
  typedecl, fields = ex.args[2:3]
  fields = isexpr(fields, :block) ? fields.args : [fields]

  argmeta = Expr[]
  filter!(fields) do ex
    if isexpr(ex, :macrocall) && ex.args[1] == Symbol("@arg")
      push!(argmeta, ex)
      false
    else
      true
    end
  end

  t = typedecl
  isexpr(t, :(<:)) && (t = first(t.args))
  t_with_parameters = t
  parameters = nothing
  isexpr(t, :curly) && ((t, parameters) = (t.args[1], t.args[2:end]))
  @assert t isa Symbol
  exprs = Expr[]
  lengths = Dict{Symbol,Any}()
  fieldnames = Symbol[]
  field_linenums = LineNumberNode[]
  fields_nolinenums = filter(fields) do x
    !isa(x, LineNumberNode) && return true
    push!(field_linenums, x)
    false
  end
  # Ignore linenums for `@arg x` definitions.
  field_linenums = field_linenums[begin+length(argmeta):end]
  required_fields = Symbol[]
  fields_withlength = Symbol[]
  for ex in fields_nolinenums
    if isexpr(ex, :call) && ex.args[1] == :(=>)
      (field, l) = ex.args[2:3]
      isexpr(field, :(::)) && (field = first(field.args))
      lengths[field] = l
      push!(fieldnames, field)
      push!(fields_withlength, field)
      isa(l, Symbol) && push!(required_fields, l)
    else
      isa(ex, Symbol) && error("Field $(repr(ex)) must be typed.")
      isexpr(ex, :call) && ex.args[1] == :(<<) && (ex = ex.args[2])
      field = isexpr(ex, :(::)) ? first(ex.args) : ex::Symbol
      push!(fieldnames, field)
    end
  end

  body = Expr(:block, source, :(__origin__ = position(io)))
  for (linenum, var, field) in zip(field_linenums, fieldnames, fields_nolinenums)
    push!(body.args, linenum, :($var = $(read_expr(field, linenum))))
  end
  push!(body.args, :($t_with_parameters($(fieldnames...))))
  fdef = :(Base.read(io::IO, ::Type{$t_with_parameters}))
  fdecl = isnothing(parameters) ? fdef : Expr(:where, fdef, parameters...)
  for ex in argmeta
    if isexpr(ex, :macrocall) && ex.args[1] == Symbol("@arg")
      argex = last(ex.args)
      Meta.isexpr(argex, :(=)) && (argex.head = :kw)
      push!(fdef.args, argex)
    end
  end
  read_f = Expr(:function, fdecl, body)

  fields = map(fields) do ex
    isexpr(ex, :call) && return ex.args[2]
    ex
  end
  struct_def = Expr(:struct, ex.args[1:2]..., Expr(:block, fields...))
  quote
    Core.@__doc__ $struct_def
    $read_f
  end
end

"""
Mark a given struct as serializable, automatically implementing `Base.read`.

If some of the structure members are vectors, their length
must be specified using a syntax of the form `params::Vector{UInt32} => param_count`
where `param_count` can be any expression, which may depend on other structure members.

Fields can be read in a custom manner by using a syntax of the form
`params::SomeField << ex` where `ex` can be e.g. `read(io, SomeField, other_field.length)`
where `other_field` can refer to any previous field in the struct. This expression may
refer to a special variable `__origin__`, which is the position of the IO before parsing the struct.

Additional arguments required for `Base.read` can be specified with the syntax `@arg name` at the very start of the structure,
before any actual fields. In this way, the definition for `Base.read` will include these extra arguments. Calling code
will then have to provide these extra arguments.

`LineNumberNode`s will be preserved and inserted wherever necessary to keep stack traces informative.

# Examples

```julia
@serializable struct MarkArrayTable
  mark_count::UInt16
  mark_records::Vector{MarkRecord} => mark_count
end
```

```julia
@serializable struct LigatureAttachTable
  @arg mark_class_count # will need to be provided when `Base.read`ing this type.

  # Length of `component_records`.
  component_count::UInt16

  component_records::Vector{Vector{UInt16}} << [[read(io, UInt16) for _ in 1:mark_class_count] for _ in 1:component_count]
end
```

Here is an advanced example which makes use of all the features:

```julia
@serializable struct LigatureArrayTable
  @arg mark_class_count # will need to be provided when `Base.read`ing this type.

  # Length of `ligature_attach_offsets`.
  ligature_count::UInt16

  # Offsets in bytes from the origin of the structure to data blocks formatted as `LigatureAttachTable`s.
  ligature_attach_offsets::Vector{UInt16} => ligature_count

  ligature_attach_tables::Vector{LigatureAttachTable} << [read_at(io, LigatureAttachTable, offset, mark_class_count; start = __origin__) for offset in ligature_attach_offsets]
end
```
"""
macro serializable(ex)
  try
    ex = serializable(ex, __source__)
  catch
    (; file, line) = __source__
    @error "An error happened while parsing an expression at $file:$line"
    rethrow()
  end

  esc(ex)
end
