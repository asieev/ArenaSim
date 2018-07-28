using Statistics
using ArenaSim


deckfiles = readdir(joinpath(@__DIR__, "decks"))
decks = map(fn -> ArenaSim.deckreader_mtga_format(joinpath(@__DIR__, "decks", fn)),
     deckfiles)

xs = shufflesim(ArenaSim.deckinfo.(decks); parameters = SimParameters(), reps = 300, batchsize = 50);

# Packs to get each deck
mean(reduce(+, values(xs.packs_opened)), dims = 1)

# Source of rare cards
@doc SimOutput

signif.(mean(xs.card_sources, dims = 1)[1,:,3,:],  3)

# Average pack WC drop rates:
map(i -> mean(xs2.total_pack_wcs[:,i] ./ xs2.total_packs), 1:4)
