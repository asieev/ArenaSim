import DelimitedFiles
import Random

"""
    PityTimerSamples

Stochastic parameters that determine pack opening behavior.  Wildcards in packs
are assumed to have a base rate that increases by an increment each time one isn't opened
in a pack.  For the rare/mythic slot, the remaining probability not occupied by the
wildcard pity timers is divided into rare or mythic pulls by the `rare_card` parameter. This
representation is used to incorporate uncertainty in WC rates into pack estimates.
"""
struct PityTimerSamples
 common_wild_card_base::Vector{Float64}
 common_wild_card_increment::Vector{Float64}
 uncommon_wild_card_base::Vector{Float64}
 uncommon_wild_card_increment::Vector{Float64}
 rare_card::Vector{Float64}
 mythic_card::Vector{Float64}
 rare_wild_card_base::Vector{Float64}
 rare_wild_card_increment::Vector{Float64}
 mythic_wild_card_base::Vector{Float64}
 mythic_wild_card_increment::Vector{Float64}
 change_point::Vector{Float64}
 ptpower::Vector{Float64}
end

"""
    PityTimerParameters

One draw from `PityTimerSamples`
"""
struct PityTimerParameters
 common_wild_card_base::Float64
 common_wild_card_increment::Float64
 uncommon_wild_card_base::Float64
 uncommon_wild_card_increment::Float64
 rare_card::Float64
 mythic_card::Float64
 rare_wild_card_base::Float64
 rare_wild_card_increment::Float64
 mythic_wild_card_base::Float64
 mythic_wild_card_increment::Float64
 change_point::Float64
 ptpower::Float64
end

function Random.:rand(x::PityTimerSamples)
 i = rand(1:length(x.rare_card))
 PityTimerParameters(
   x.common_wild_card_base[i],
   x.common_wild_card_increment[i],
   x.uncommon_wild_card_base[i],
   x.uncommon_wild_card_increment[i],
   x.rare_card[i],
   x.mythic_card[i],
   x.rare_wild_card_base[i],
   x.rare_wild_card_increment[i],
   x.mythic_wild_card_base[i],
   x.mythic_wild_card_increment[i],
   x.change_point[i],
   x.ptpower[i]
 )
end

let
 local mat, header = DelimitedFiles.readdlm(
     joinpath(@__DIR__, "..", "data", "packmodel_samples.csv"), ',';
     header = true
 )

 @assert size(mat,2) == 12

 global const pity_timer_samps = PityTimerSamples(
     mat[:,1],
     mat[:,2],
     mat[:,3],
     mat[:,4],
     mat[:,5],
     mat[:,6],
     mat[:,7],
     mat[:,8],
     mat[:,9],
     mat[:,10],
     mat[:,11],
     mat[:,12]
 )

end
