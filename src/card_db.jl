export card_db

const card_db =  eval(Meta.parse(read("data/card_db.txt", String)))

## Decklists often don't have the full name of flip cards
## Add some synonyms
const multicards = filter( x -> occursin(r" // ", x["name"]), card_db)

function splitter(x)
    mobj = match(r" // ", x)
    offset = mobj.offset
    String(strip(x[1:(offset-1)]))
end

function three_parens(x)
    ans = replace(x, r" // " => " /// ")
    ans
end

const multicard_synonyms  = Dict( (splitter(x["name"]), x["name"]) for x in multicards)
for x in multicards
    multicard_synonyms[three_parens(x["name"])] = x["name"]
end
