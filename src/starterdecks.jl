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

const basiccards = let
    dir = joinpath(@__DIR__, "..", "data", "starterdecks")
    files = readdir(dir)
    filter!(x -> in(x, ["W.txt", "U.txt", "B.txt", "R.txt", "G.txt"]), files)
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


const kldgrant = let
    file = joinpath(@__DIR__, "..", "data", "KLD_starter", "kld_starter.txt" )
    deck = deckreader_mtga_format( file )
    deck = deckinfo(deck)
    
    col = array_rep_all(card_db)
    for elem in deck
        ix = first(elem.prints).index
        col[ix] += elem.amount
    end

    for r in 1:4
        for s in [:KLD, :AER]
            for ix in indices_set_rarity(card_db, s, r)
                col[ix] += r > 3 ? 1 : 2
            end
        end
    end
    
    for i in eachindex(col)
        if col[i] > 4
            col[i] = 4
        end
    end
    col
    
end