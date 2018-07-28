export Cycle, advance!, nextitem!

mutable struct Cycle{T}
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

function nextitem!(x::Cycle{T}) where T
    advance!(x)
    x.data[x.pos]
end

function Base.:getindex(x::Cycle{T}, i) where T
    getindex(x.data, i)
end
