function process_icr!(;collection, table, account, rarity, parameters, logging_vector)
    card = rand(table)
    if collection[card] < 4
        collection[card] += 1
        push!(logging_vector, card)
    else
        account.vault_pct += parameters.duplicate_vpct[rarity]
    end
    collection
end
