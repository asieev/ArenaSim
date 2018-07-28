function winrate_table(rate, reps)
    d = Bernoulli(rate)
    ans = zeros(Int, reps)
    for i = 1:reps
        losses = 0
        wins = 0
        while losses < 3 && wins < 7
            if rand(d) == 0
                losses += 1
            else
                wins += 1
            end
        end
        ans[i] = wins
    end
    ans
end
