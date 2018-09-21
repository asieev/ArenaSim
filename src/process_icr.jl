function process_icr!(;collection, openable_cards, account, rarity, parameters, logging_vector)
    if isempty(openable_cards.by_rarity[rarity])
        @goto vault_increment
    end
    card = rand(openable_cards.by_rarity[rarity])
    if collection[card] < 4
        collection[card] += 1
        push!(logging_vector, card)
        if collection[card] >= 4 && parameters.prevent_duplicates
            remove_fully_collected!(card, rarity; openable_cards = openable_cards)
        end
    else
        @label vault_increment
        account.vault_pct += parameters.duplicate_vpct[rarity]
    end
    collection
end
