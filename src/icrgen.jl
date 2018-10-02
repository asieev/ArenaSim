function icrgen_qc(winrate, n1, n2;uncommon_icr_probs = [0, 0.85, 0.10, 0.05], rare_icr_probs = [0,0,66/100,33/100])
	first_icr = Dict( (w,uncommon_icr_probs) for w in 0:7)
	second_icr = deepcopy(first_icr)
	second_icr[6] = rare_icr_probs
	second_icr[7] = rare_icr_probs
	third_icr = deepcopy(second_icr)
	for i in 4:5
		third_icr[i] = rare_icr_probs
	end

	avg_first_icr = sum( pdfnegbin_truncated(k; p = winrate, r = 3, maxwins = 7) .* first_icr[k] for k in 0:7 )
	avg_second_icr = sum( pdfnegbin_truncated(k; p = winrate, r = 3, maxwins = 7) .* second_icr[k] for k in 0:7 )
	avg_third_icr = sum( pdfnegbin_truncated(k; p = winrate, r = 3, maxwins = 7) .* third_icr[k] for k in 0:7 )

	if n1 > 0
		icrvec = [[ Categorical(avg_first_icr), Categorical(avg_second_icr), Categorical(avg_third_icr) ] for i in 1:n1]
		for i in 1:n2
			push!(icrvec, Categorical{Float64}[])
		end
		icrcycle = Cycle(  icrvec )
	else
		icrcycle = Cycle( [Categorical{Float64}[]] )
	end

	icrcycle
end