inv_logit(x) = 1/(1 + exp(-x))

function wcdraw!(account, pars::PityTimerParameters)::Tuple{Int64,Int64,Int64}
    p = zeros(Float64, 4)

    p[2] = pars.rare_wild_card_base + pars.rare_wild_card_increment * account.pitytimer[3]
    p[4] = pars.mythic_wild_card_base + pars.mythic_wild_card_increment * account.pitytimer[4]

    p[1] = pars.rare_proportion * (1 - p[2] - p[4])
    p[3] = 1 - p[1] - p[2] - p[4]

    raredraw = rand(Categorical(p))

    if raredraw == 2
        account.pitytimer[3] = 0
        account.wc_count[3] += 1
    else
        account.pitytimer[3] += 1
    end

    if raredraw == 4
        account.pitytimer[4] = 0
        account.wc_count[4] += 1
    else
        account.pitytimer[4] += 1
    end

    pc = inv_logit(pars.common_wild_card_base + pars.common_wild_card_increment * account.pitytimer[1])
    pu = inv_logit(pars.uncommon_wild_card_base + pars.uncommon_wild_card_increment * account.pitytimer[2])

    commondraw = rand(Bernoulli(pc))
    uncommondraw = rand(Bernoulli(pu))

    if commondraw == 1
        account.pitytimer[1] = 0
        account.wc_count[1] += 1
    else
        account.pitytimer[1] += 1
    end

    if uncommondraw == 1
        account.pitytimer[2] = 0
        account.wc_count[2] += 1
    else
        account.pitytimer[2] += 1
    end

    commondraw, uncommondraw, raredraw
end

function open_pack!(pack_contents; set,  collection, pitytimer_parameters, account,
     draw_table, parameters, logging_vector, output, rep)

    common_wc, uncommon_wc, rareslot = wcdraw!(account, pitytimer_parameters)

    for r in 1:4
        rand!(pack_contents[r], draw_table[(set,r)])
    end

    if common_wc == 1
        pack_contents[1][1] = 0
        output.total_pack_wcs[rep,1] += 1
    end
    if uncommon_wc == 1
        pack_contents[2][1] = 0
        output.total_pack_wcs[rep,2] += 1
    end

    if rareslot == 1 # Rare card
        fill!(pack_contents[4], 0)
    elseif rareslot == 3 # Mythic card
        fill!(pack_contents[3], 0)
    else # Wildcard
        fill!(pack_contents[4], 0)
        fill!(pack_contents[3], 0)
    end

    if rareslot == 2
        output.total_pack_wcs[rep,3] += 1
    end

    if rareslot == 4
        output.total_pack_wcs[rep,4] += 1
    end

    pack_to_collection!(collection; pack_contents = pack_contents,
     account = account, parameters = parameters, logging_vector = logging_vector)

     output.total_packs[rep] += 1

end

function pack_to_collection!(collection; pack_contents, account,
     parameters, logging_vector)
    for r in 1:4
        for card in pack_contents[r]
            if card > 0
                if collection[card] < 4
                    collection[card] += 1
                    push!(logging_vector, card)
                else
                    account.vault_pct += parameters.duplicate_vpct[r]
                end
            end
        end
    end
end
