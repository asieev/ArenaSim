function array_rep_all(db)
    zeros(Int, length(db))
end

function indices_set_rarity(db, set, rarity)
    findall(x -> x["set"] == set && x["rarity"] == rarity, db)
end

function indices_rarity(db, rarity::Int)::Vector{Int}
    findall(x -> x["rarity"] == rarity, db)
end


function indices_set(db, set)
    findall(x -> x["set"] == set, db)
end
