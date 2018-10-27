function remove_fully_collected!(id::Int, set::Symbol, rarity::Int; openable_cards)
    filter!(z -> z != id, openable_cards.by_rarity[rarity])
    if haskey(openable_cards.by_set_rarity, (set,rarity))
        filter!(z -> z != id, openable_cards.by_set_rarity[(set,rarity)])
    end
    
    openable_cards
end

function remove_fully_collected!(id::Int, rarity::Int; openable_cards)
    for set in openable_cards.sets
        remove_fully_collected!(id, set, rarity; openable_cards = openable_cards)
    end

    openable_cards
end

function remove_fully_collected!(id::Int; openable_cards)
    for r in 1:4
        remove_fully_collected!(id, r; openable_cards = openable_cards)
    end

    openable_cards
end
