export simulate

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
    collection = array_rep_all(db)

    cards_by_rarity = map(i -> indices_rarity(db, i), 1:4)
    cards_by_set = Dict(map(s -> (s, indices_set(db, s)), sets))
    cards_by_set_rarity =  Dict(
     ((s,r), indices_set_rarity(db,s,r)) for s in sets, r in 1:4
     )

    cards_by_rarity_noopen = map(i -> setdiff(indices_rarity(db, i), parameters.noopen_cards), 1:4)
    cards_by_set_rarity_noopen =  Dict(
      ((s,r), setdiff(indices_set_rarity(db,s,r), parameters.noopen_cards)) for s in sets, r in 1:4
    )

    account = AccountState()
    for set in keys(parameters.bonus_packs)
        account.bonus_packs[set] += parameters.bonus_packs[set]
    end
    output = SimOutput(nreps, length(deckinfos), sets)
    freshaccount = deepcopy(account)

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

        collection = deepcopy(parameters.starter_cards)
        account = deepcopy(freshaccount)

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
                     logging_vector = wc_crafts_gained)
                    break
                end

                set = parameters.nextset(collection, account, current_deck, sets, cards_by_set_rarity)

                if account.bonus_packs[set] == 0
                    # TODO: Fill out ICR machinery
                    icr_sequence = nextitem!(parameters.icrs_per_pack)
                    for dist in icr_sequence
                        icr_rarity = rand(dist)
                        process_icr!(collection = collection, table =  cards_by_rarity_noopen[icr_rarity],
                            account = account, rarity = icr_rarity, parameters = parameters,
                            logging_vector = icrs_gained)
                    end

                    # TODO: Raredrafting simulation?

                    push!(packs_opened, set)
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
                  draw_table = cards_by_set_rarity_noopen,
                  parameters = parameters,
                  logging_vector = pack_cards_gained,
                  output = output,
                  rep = rep
                )
            end

            for packset in packs_opened
                output.packs_opened[packset][rep,deckindex] += 1
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
    end

    output
end
