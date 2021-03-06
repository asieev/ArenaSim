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

function deckinfo(cardname, amount::Int; card_db = card_db)::NamedTuple{(:name, :amount, :prints),Tuple{String,Int64,Array{NamedTuple{(:index, :set, :rarity),Tuple{Int64,Symbol,Int64}},1}}}
    prints = findall(y -> y["name"] == cardname, card_db)
    if length(prints) == 0
        error("Unknown card $cardname")
    end
    (name = cardname, amount = amount,
     prints = map(i -> (index = i, set = card_db[i]["set"], rarity = card_db[i]["rarity"]), prints))
end


function reduce_deck(deck; additive = true, card_db = card_db)
    reduced = similar(deck, 0)

    for elem in deck
        ix = findfirst(x -> x.name == elem.name, reduced)

        if ix == nothing
            push!(reduced, elem)
        else
            if additive
                reduced[ix] = deckinfo(elem.name, min(4, reduced[ix].amount + elem.amount); card_db = card_db)
            else
                reduced[ix] = deckinfo(elem.name, min(4, max(reduced[ix].amount, elem.amount)); card_db = card_db)
            end
        end
    end

    reduced
end


"""
    deckinfo(deck::Vector{Tuple{String,Int}})

Processes a vector of card names and required quantities into a form that incorporates
set information, card rarity, and prints across multiple sets.
"""
function deckinfo(deck::Vector{Tuple{String,Int}}; card_db = card_db)
    reduce_deck(map(x -> deckinfo(x[1], x[2]; card_db = card_db), deck);
     additive = true, card_db = card_db)
end

function deckinfo(x::Deckinfo; card_db = card_db)
    reduce_deck(x; additive = true, card_db = card_db)
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
