const startercards = let
    dir = joinpath(@__DIR__, "..", "data", "starterdecks")
    files = readdir(dir)
    decklists = deckreader_mtga_format.( joinpath.(dir, files) )
    starterdecks = deckinfo.(decklists)
    col = array_rep_all(card_db)
    for deck in starterdecks
        for elem in deck
            ix = first(elem.prints).index
            col[ix] += elem.amount
            if col[ix] > 4
                col[ix] = 4
            end
        end
    end
    col
end
