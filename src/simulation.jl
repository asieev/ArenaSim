export simulate

mutable struct OpenableCards
    by_rarity::Vector{Vector{Int}}
    by_set_rarity::Dict{Tuple{Symbol,Int},Vector{Int}}
    fresh_by_rarity::Vector{Vector{Int}}
    fresh_by_set_rarity::Dict{Tuple{Symbol,Int},Vector{Int}}
    sets::Vector{Symbol}
end

function OpenableCards(x::Vector{Vector{Int}}, y::Dict{Tuple{Symbol,Int},Vector{Int}}, sets::Vector{Symbol})
    OpenableCards(x,y,deepcopy(x),deepcopy(y),sets)
end

function update_openables(sets; parameters, db, collection)
    openables = OpenableCards(
            map(i -> setdiff( findall(x ->  x["rarity"] == i && in(x["set"], sets), db),
                              parameters.noopen_cards), 1:4),
            Dict(
                ((s,r), setdiff(indices_set_rarity(db,s,r), parameters.noopen_cards)) for s in sets, r in 1:4
            ), sets
        )

    if parameters.prevent_duplicates
        for i in eachindex(collection)
            if collection[i] >= 4
                remove_fully_collected!(i; openable_cards = openables)
            end
        end
    end

    openables
end

"""
    simulate(nreps::Int, deckinfos; kwargs...)

Main simulation function for a fixed deck order, producing a `SimOutput`.

# Arguments
- `nreps::Int`: number of iterations to run
- `deckinfos`: A vector produced by `deckinfo` representing a sequence of decks to acquire
- `parameters`: A `SimParameters` value for simulation parameters
- `db`: Database of card info
- `sets`: Sets to simulate.
"""
function simulate(nreps::Int, deckinfos; parameters = SimParameters(), db = card_db, sets = sets)
    collection = deepcopy(parameters.starter_cards)
    fresh_openable_cards = update_openables(sets; parameters = parameters, db = db, collection = collection)



    account = AccountState(parameters)

    output = SimOutput(nreps, length(deckinfos), sets, collection)

    if parameters.track_collection_progress
        output.collection_progress = Array{Union{Missing,Int}}(missing, nreps, parameters.max_track_progress_packs, length(collection))
    end

    if parameters.welcome_bundle
        account.bonus_packs[parameters.welcome_bundle_set] += 5
        set = next_set_welcome_bundle!(collection, account, first(deckinfos), sets, fresh_openable_cards)
        account.bonus_packs[set] += 12
    end

    freshaccount = deepcopy(account)

    fresh_fixed_pack_track = deepcopy(parameters.fixed_pack_track)

    pack_contents = [
        zeros(Int, 5),
        zeros(Int, 2),
        zeros(Int, 1),
        zeros(Int, 1)
    ]

    packs_opened = Symbol[]
    bonus_packs_opened = Symbol[]
    icrs_gained = Int[]
    pack_cards_gained = Int[]
    wc_crafts_gained = Int[]

    overall_icrs_gained = Int[]
    overall_pack_cards_gained = Int[]
    overall_wc_crafts_gained = Int[]

    before = NamedTuple{(:card, :needed, :rarity),Tuple{Int64,Float64,Int64}}[]
    after = NamedTuple{(:card, :needed, :rarity),Tuple{Int64,Float64,Int64}}[]

    for rep in 1:nreps
        pitytimer_parameters = rand(parameters.pitytimer_distribution)

        resize!(overall_icrs_gained, 0)
        resize!(overall_pack_cards_gained, 0)
        resize!(overall_wc_crafts_gained, 0)

        if parameters.fixed_starter
            collection = deepcopy(parameters.starter_cards)
        else
            collection = deepcopy(rand(startersequences))
        end
        openable_cards = deepcopy(fresh_openable_cards)

        if parameters.kaladesh_grant
            for i in eachindex(collection)
                collection[i] += kldgrant[i]
                if collection[i] > 4
                    collection[i] = 4
                end
            end
        end
        account = deepcopy(freshaccount)

        if parameters.prevent_duplicates
            for i in eachindex(collection)
                if collection[i] >= 4
                    remove_fully_collected!(i; openable_cards = openable_cards)
                end
            end
        end

        parameters.fixed_pack_track = deepcopy(fresh_fixed_pack_track)

        for deckindex in eachindex(deckinfos)
            resize!(packs_opened, 0)
            resize!(bonus_packs_opened, 0)
            resize!(icrs_gained, 0)
            resize!(pack_cards_gained, 0)
            resize!(wc_crafts_gained, 0)

            current_deck = deckinfos[deckindex]
            before = deck_status(collection = collection, current_deck = current_deck)

            while missing_cards(collection, current_deck)
                if account.vault_pct > 100.0
                        open_vault!(account, output; rep = rep)
                end

                if can_finish_deck(collection, account, current_deck)
                    spend_wildcards!(account = account, collection = collection,
                     current_deck =  current_deck, output = output, rep = rep, deckindex = deckindex,
                     logging_vector = wc_crafts_gained, parameters = parameters, openable_cards = openable_cards)

                    @assert !missing_cards(collection, current_deck)
                    @goto cleanup
                end

                if any(x -> x < Inf, parameters.wc_upgrade_rate)
                    convert_wildcards!(account, parameters)
                end

                set = parameters.nextset(collection, account, current_deck, sets, openable_cards)

                if account.bonus_packs[set] == 0
                    if haskey(parameters.openable_schedule, output.total_earned_packs[rep])
                        openable_cards = update_openables(parameters.openable_schedule[output.total_earned_packs[rep]]; parameters = parameters,
                            collection = collection, db = db)
                    end

                    icr_sequence = nextitem!(parameters.icrs_per_pack)
                    for dist in icr_sequence
                        icr_rarity = rand(dist)
                        process_icr!(collection = collection, openable_cards = openable_cards,
                            account = account, rarity = icr_rarity, parameters = parameters,
                            logging_vector = icrs_gained)
                    end

                    # TODO: Raredrafting simulation?

                    fixedpack = nextitem!(account.fixed_pack_track)

                    if !ismissing(fixedpack)
                        set = fixedpack
                    end

                    if !in(set, openable_cards.sets)
                        set = rand(openable_cards.sets)
                    end

                    push!(packs_opened, set)
                    output.total_earned_packs[rep] += 1
                else
                    account.bonus_packs[set] -= 1
                    push!(bonus_packs_opened, set)
                end

                account.vault_pct += parameters.pack_vault_pct

                timer_result = nextitem!(account.wc_timer)
                if timer_result > 0
                    account.wc_count[timer_result] += 1
                end

                open_pack!(
                  pack_contents;
                  set =  set,
                  collection = collection,
                  pitytimer_parameters = pitytimer_parameters,
                  account =  account,
                  openable_cards = openable_cards,
                  parameters = parameters,
                  logging_vector = pack_cards_gained,
                  output = output,
                  rep = rep
                )

                @label cleanup

                if parameters.track_collection_progress
                    output.collection_progress[rep,output.total_packs[rep],:] = deepcopy(collection)
                end

            end

            for packset in packs_opened
                output.packs_opened[packset][rep,deckindex] += 1
            end

            for packset in bonus_packs_opened
                output.bonus_packs_opened[packset][rep,deckindex] += 1
            end

            append!(overall_icrs_gained, icrs_gained)
            append!(overall_pack_cards_gained, pack_cards_gained)
            append!(overall_wc_crafts_gained, wc_crafts_gained)

            after = deck_status(collection = collection,current_deck =  current_deck)

            for i in eachindex(after)
                rarity = before[i].rarity
                card = before[i].card
                output.card_sources[rep,deckindex,rarity,1] += before[i].total
                output.card_sources[rep,deckindex,rarity,2] += before[i].needed
                output.card_sources[rep,deckindex,rarity,3] += after[i].needed
            end

            cards_gained_counter!(output, wc_crafts_gained, before; rep = rep,
             deckindex = deckindex, column = 4)
            cards_gained_counter!(output, pack_cards_gained, before; rep = rep,
             deckindex = deckindex, column = 5)
            cards_gained_counter!(output, icrs_gained, before; rep = rep,
             deckindex = deckindex, column = 6)
            cards_gained_counter!(output, overall_wc_crafts_gained, before; rep = rep,
             deckindex = deckindex, column = 7)
            cards_gained_counter!(output, overall_pack_cards_gained, before; rep = rep,
             deckindex = deckindex, column = 8)
            cards_gained_counter!(output, overall_icrs_gained, before; rep = rep,
              deckindex = deckindex, column = 9)
        end
        output.ending_collection[rep,:] = collection
    end

    maxpacks = maximum(output.total_packs)
    if length(output.collection_progress) > 0 && maxpacks < parameters.max_track_progress_packs
        output.collection_progress = output.collection_progress[:,1:maxpacks,:]
    end

    output
end
