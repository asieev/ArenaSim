function missing_cards(collection, current_deck)
    for elem in current_deck
        if elem.amount > sum_over_prints(collection, elem.prints)
            return true
        end
    end
    return false
end

function deck_status(; collection, current_deck)
    ans = NamedTuple{(:card, :total, :needed, :rarity),Tuple{Int64,Float64,Float64,Int64}}[]
    for elem in current_deck
        needed = max(0,elem.amount - sum_over_prints(collection, elem.prints))
        for print in elem.prints
            push!(ans, (card = print.index, total = elem.amount / length(elem.prints),
             needed = needed / length(elem.prints), rarity = print.rarity))
        end
    end
    ans
end

function can_finish_deck(collection, account, current_deck)
    needed_wcs = [0,0,0,0]
    for elem in current_deck
        needed = elem.amount - sum_over_prints(collection, elem.prints)
        if needed > 0
            # NOTE: Minimum rarity might not be best if rare WCs are bottleneck and
            # there are reprints between rare and mythic
            rarity = minimum(x -> x.rarity, elem.prints)
            needed_wcs[rarity] += needed
        end
    end
    all(needed_wcs[i] <= account.wc_count[i] for i in 1:4)
end

function spend_wildcards!(; account, collection, current_deck, output, rep,
     deckindex, logging_vector, parameters, openable_cards)
    for elem in current_deck
        r = minimum(x -> x.rarity, elem.prints)
        i = elem.prints[1].index
        set = elem.prints[1].set
        while (account.wc_count[r] > 0) && (elem.amount - sum_over_prints(collection, elem.prints) > 0)
            account.wc_count[r] -= 1
            output.wcs_spent_on_decks[rep,deckindex,r] += 1
            collection[i] += 1
            if collection[i] >= 4 && parameters.prevent_duplicates
                remove_fully_collected!(i, set, r; openable_cards = openable_cards)
            end
            push!(logging_vector, i)
        end
    end
end

function next_set!(collection, account, current_deck, sets, openable_cards)::Symbol
    for set in sets
        if account.bonus_packs[set] > 0
            return set
        end
    end

    count_sets_with_high_rarity!(set_counter, collection, current_deck, openable_cards.by_set_rarity )
    argmax(set_counter)
end

function next_set_welcome_bundle!(collection, account, current_deck, sets, openable_cards)::Symbol
    count_sets_with_high_rarity!(set_counter, collection, current_deck, openable_cards.by_set_rarity )
    argmax(set_counter)
end

function next_set_m19!(collection, account, current_deck, sets, openable_cards)::Symbol
    :M19
end

function next_set_dom!(collection, account, current_deck, sets, openable_cards)::Symbol
    :DOM
end

function count_sets_with_high_rarity!(d::Dict{Symbol,Float64}, collection, deck, length_lookup)
    for k in keys(d)
        d[k] = 0.0
    end

    for elem in deck
        for print in elem.prints
            if print.rarity >= 3
                d[print.set] += max(0.0, elem.amount - sum_over_prints(collection, elem.prints)) /
                   (length(length_lookup[(print.set, 3)]) + length(length_lookup[(print.set, 4)]))
            end
        end
    end

    d
end
