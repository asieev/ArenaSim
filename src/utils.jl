function cards_gained_counter!( output::SimOutput, cards_gained::Vector{Int}, deckstatus; rep, deckindex, column)
    for card in cards_gained
        for elem in deckstatus
            if card == elem.card
                @inbounds output.card_sources[rep,deckindex,elem.rarity,column] += 1
            end
        end
    end
end

function sum_over_prints(collection, prints)
    sum = 0
    for p in prints
        sum += collection[p.index]
    end
    sum
end

function deckinfo(cardname, amount::Int)::NamedTuple{(:name, :amount, :prints),Tuple{String,Int64,Array{NamedTuple{(:index, :set, :rarity),Tuple{Int64,Symbol,Int64}},1}}}
    prints = findall(y -> y["name"] == cardname, card_db)
    if length(prints) == 0
        error("Unknown card $cardname")
    end
    (name = cardname, amount = amount,
     prints = map(i -> (index = i, set = card_db[i]["set"], rarity = card_db[i]["rarity"]), prints))
end

"""
    deckinfo(deck::Vector{Tuple{String,Int}})

Processes a vector of card names and required quantities into a form that incorporates
set information, card rarity, and prints across multiple sets.
"""
function deckinfo(deck::Vector{Tuple{String,Int}})
    map(x -> deckinfo(x[1], x[2]), deck)
end

function deckinfo(x::Deckinfo)
    x
end

function icr_count(x)
    min = floor(Int, x)
    chc = x - min
    if rand() < chc
        return min + 1
    else
        return min
    end
end
