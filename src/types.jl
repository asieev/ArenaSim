const Deckinfo = Array{NamedTuple{(:name, :amount, :prints),Tuple{String,Int64,Array{NamedTuple{(:index, :set, :rarity),Tuple{Int64,Symbol,Int64}},1}}},1}

"""
    SimParameters

Parameters to adjust certain aspects of the simulation:
- `pitytimer_distribution`: Collection of samples determining the distribution of parameters
   used in the pack opening and pitytimers.  See `?PityTimerSamples`
- `wc_timer_track`: Vector representing the WC rarities associated with the timer tracks.  Each pack
   opened advances the position and then resets at the end.  0 is associated with no wildcard, 2 to 4
   correspond to uncommon through mythic.
- `icrs_per_pack`: A `Cycle` of vectors of 4-dimensional categorical distributions representing
   probabilistic ICR rarities associated with each pack, e.g. to simulate doing constructed events
   in between buying packs.  Each pack opened advances to the next vector of distributions, and then an
   ICR rarity is drawn from each distribution in the vector.
- `pack_vault_pct`: Vault percentage associated with opening a pack.  Defaults to 0% as of M19.
- `duplicate_vpct`: Vault percentage associated with an excess copy of a card of each rarity
- `noopen_cards`: Cards that don't show up in packs on account of being promos or banned
- `starter_cards`: Cards from NPE decks assumed to be in everyone's collection relatively quickly
- `bonus_packs`: One-time packs from, e.g. NPE, that don't count against the total packs
"""
@with_kw mutable struct SimParameters
    pitytimer_distribution::PityTimerSamples = pity_timer_samps
    wc_timer_track::Vector{Int} = [0,0,2,0,0,3,0,0,2,0,0,3,0,0,2,0,0,4,0,0,2,0,0,3,0,0,2,0,0,3]
    icrs_per_pack::Cycle{Vector{Categorical{Float64}}} = Cycle( [ Categorical{Float64}[], [Categorical( [0,.9,.09,.01])] ] )
    pack_vault_pct::Float64 = 0.0
    duplicate_vpct::NTuple{4,Float64} = (1/9, 1/3, 5/9, 1+1/9)
    noopen_cards::Vector{Int} = map(x -> first(x.prints).index, deckinfo(deckreader_mtga_format(joinpath(@__DIR__, "..", "data", "noopen_cards.txt"))))
    starter_cards::Vector{Int} = startercards
    bonus_packs::Dict{Symbol,Int} = Dict( :M19 => 3 )
    nextset::Function = next_set!
    wc_upgrade_rate::Vector{Float64} = [Inf,Inf,Inf,Inf]
    wc_upgrade_threshold::Vector{Int} = [20,20,100,0]
    welcome_bundle::Bool = false
    kaladesh_grant::Bool = false
    prevent_duplicates::Bool = false
    starting_wc_count::Vector{Int} = [4,2,1,0]
end

"""
    AccountState

Represents non-card aspects of an account: Vault percentage, wildcard counts,
bonus packs that don't count against output statistics (e.g. from NPE), pitytimer
for pack-based wildcards, and the position on the wildcard timer tracks
"""
@with_kw mutable struct AccountState
    vault_pct::Float64 = 0.0
    wc_count::Vector{Int} = [0,0,0,0]
    bonus_packs::Dict{Symbol,Int} = Dict( (s, 0) for s in sets)
    pitytimer::Vector{Int} = [0,0,0,0]
    wc_timer::Cycle{Int} = Cycle(SimParameters().wc_timer_track, 0)
end

function AccountState(parameters::SimParameters)
    account = AccountState()
    account.wc_count = deepcopy(parameters.starting_wc_count)

    for set in keys(parameters.bonus_packs)
        account.bonus_packs[set] += parameters.bonus_packs[set]
    end

    account.wc_timer = Cycle(parameters.wc_timer_track, 0)

    account
end

"""
    SimOutput

Summarizes simulation output in terms of:
- `packs_opened`: (Non-bonus) packs opened of each set
- `wcs_from_vault`: How many wildcards came from Vault
- `wcs_spent_on_decks`: How many wildcards were spent on decks of each rarity
- `card_sources`: An estimate of card sources for each deck. Array dimensions:
    1. Simulation rep
    2. Deck order
    3. Card rarity (1 = common, ..., 4 = mythic)
    4. Various statistics, corresponding to this 9 'columns' in this dimension:
        1. Total cards of this rarity in deck (non-stochastic)
        2. Amount needed of this rarity before starting this deck
        3. Amount needed of this rarity after finishing this deck (should be 0)
        4. Cards of this rarity in this deck crafted by wildcards during its construction
        5. Cards of this rarity in this deck opened from packs during its construction
        6. Cards of this rarity in this deck opened from ICRs during its construction
        7. As in 4, except during all decks so far
        8. As in 5, except during all decks so far
        9. As in 6, except during all decks so far
- `total_pack_wcs`: Running total across an entire iteration of wildcards for each rarity
- `total_packs`: Running total across an entire iteration of packs, free or not, for each rarity
"""
@with_kw mutable struct SimOutput
    packs_opened::Dict{Symbol,Array{Int,2}}
    wcs_from_vault::Array{Int,2}
    wcs_spent_on_decks::Array{Int,3}
    card_sources::Array{Float64, 4}
    total_pack_wcs::Array{Int,2}
    total_packs::Array{Int}
end

function SimOutput(reps::Int, decks::Int, sets::Vector{Symbol})::SimOutput
    SimOutput(
        packs_opened = Dict( (s, zeros(Int, (reps, decks))) for s in sets),
        wcs_from_vault = zeros(Int, (reps, 4)),
        wcs_spent_on_decks = zeros(Int, (reps, decks, 4)),
        card_sources = zeros(Float64, (reps, decks, 4, 9)),
        total_pack_wcs = zeros(Int, (reps, 4)),
        total_packs = zeros(Int, reps)
    )
end

function copy_into_output!(total::SimOutput, partial::SimOutput; startindex::Int)
    endindex = startindex + size(partial.card_sources,1) - 1
    range = startindex:endindex

    total.wcs_from_vault[range,:] = partial.wcs_from_vault
    total.wcs_spent_on_decks[range,:,:] = partial.wcs_spent_on_decks
    total.card_sources[range,:,:,:] = partial.card_sources
    total.total_pack_wcs[range,:] = partial.total_pack_wcs
    total.total_packs[range] = partial.total_packs

    for set in keys(total.packs_opened)
        total.packs_opened[set][range,:] = partial.packs_opened[set]
    end

    endindex + 1
end
