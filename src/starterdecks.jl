function starterdeckreader(dualcolors)::Vector{Int}
    monos = ["W","U","B","R","G"] .* ".txt"
    duals = dualcolors .* ".txt"
    files = vcat(monos, duals)
    dir = joinpath(@__DIR__, "..", "data", "starterdecks")
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

const startersequences = Vector{Int}[
   starterdeckreader( ["UG", "WR", "BR", "GW", "UB"]),
   starterdeckreader( ["BR", "GW", "BW", "UG", "UR"]),
   starterdeckreader( ["BW", "UR", "RG", "UW", "GB"] ),
   starterdeckreader( ["RG", "GB", "UB", "UW", "WR"] )
]

const tenstarters = starterdeckreader( ["RG", "GB", "UB", "UW", "WR", "BW", "UR", "BR", "GW", "UG"])


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