export card_db

const card_db =  eval(Meta.parse(read(joinpath(@__DIR__,"..", "data", "card_db.txt"), String)))

## Decklists often don't have the full name of flip cards
## Add some synonyms
const multicards = filter( x -> occursin(r" // ", x["name"]), card_db)

function splitter(x)
    mobj = match(r" // ", x)
    offset = mobj.offset
    String(strip(x[1:(offset-1)]))
end

function three_slashes(x)
    ans = replace(x, r" // " => " /// ")
    ans
end

function one_slash(x)
    ans = replace(x, r" // " => "/")
    ans
end

function one_slash_with_space(x)
    ans = replace(x, r" // " => " / ")
    ans
end

const multicard_synonyms  = Dict( (splitter(x["name"]), x["name"]) for x in multicards)
for x in multicards
    multicard_synonyms[three_slashes(x["name"])] = x["name"]
    multicard_synonyms[one_slash(x["name"])] = x["name"]
    multicard_synonyms[one_slash_with_space(x["name"])] = x["name"]
end
