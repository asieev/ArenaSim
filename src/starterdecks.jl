function starterdeckreader(dualcolors)
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
