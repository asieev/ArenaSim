function open_vault!(account, output; rep)
    account.vault_pct -= 100.0
    account.wc_count[2] += 3
    account.wc_count[3] += 2
    account.wc_count[4] += 1
    output.wcs_from_vault[rep,2] += 3
    output.wcs_from_vault[rep,3] += 2
    output.wcs_from_vault[rep,4] += 1
    account
end
