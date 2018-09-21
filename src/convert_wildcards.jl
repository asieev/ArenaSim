function convert_wildcards!(account, parameters)
    for r = 1:3
        while account.wc_count[r] >= parameters.wc_upgrade_rate[r] && account.wc_count[r] >= parameters.wc_upgrade_threshold[r]
            account.wc_count[r] -= parameters.wc_upgrade_rate[r]
            account.wc_count[r+1] += 1
        end
    end
end