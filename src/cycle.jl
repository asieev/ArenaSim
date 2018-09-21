export Cycle, advance!, nextitem!

mutable struct Cycle{T} <: AbstractVector{T}
    data::Vector{T}
    pos::Int
end

function Cycle(x::Vector{T}) where T
    Cycle(x, 1)
end

function advance!(x::Cycle{T}, n::Int = 1) where T
    x.pos += n
    l = length(x.data)
    x.pos %= l
    if x.pos == 0
        x.pos = l
    end
    x
end

Base.IndexStyle(::Type{<:Cycle{T}}) where T = IndexLinear()
Base.size(x::Cycle{T}) where T = size(x.data)


function nextitem!(x::Cycle{T}) where T
    advance!(x)
    x.data[x.pos]
end

function nextitem!(x::Vector{T}) where T
    pop!(x)
end

function Base.:getindex(x::Cycle{T}, i) where T
    getindex(x.data, i)
end

Base.setindex!(A::Cycle{T}, v, i::Int) where T = setindex!(A.data, v, i)
