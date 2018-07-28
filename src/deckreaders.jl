function deckreader(file)
    lines = readlines(file)
    filter!( x -> occursin(r"^\s*\d+", x), lines)
    matches = match.(Ref(r"\s"), lines)
    matches = map(x -> x.offset, matches)
    ans = [
        ( String(strip(lines[i][matches[i]:end])),  parse_max_4(lines[i][1:(matches[i] - 1)])) for i in eachindex(lines)
    ]
    filter!(x -> !in(x[1], ["Plains", "Island", "Swamp", "Mountain", "Forest"]), ans )
end

"""
    deckreader_mtga_format(file)

Reads a decklisted exported from MTGA from a text file into the simulation format.  
"""
function deckreader_mtga_format(file)
    lines = readlines(file)
    filter!(x -> occursin(r"^\s*\d+", x), lines)
    matches = eachmatch.(Ref(r"\s"), lines)
    matches = map(x -> [y.offset for y in x], matches)
    # NOTE: This won't work for a couple of UN-set cards with parens in names
    parens = map(x -> match(r"\(", x).offset, lines)
    end_of_name = [ maximum(filter(x -> x < parens[i], matches[i])) for i in eachindex(lines)]
    end_of_count = first.(matches)

    count = [ parse_max_4(lines[i][1:(end_of_count[i])]) for i in eachindex(lines) ]
    name = [ String(strip(lines[i][end_of_count[i]:end_of_name[i]])) for i in eachindex(lines) ]


    ans = collect(zip(name, count))
    filter!(x -> !in(x[1], ["Plains", "Island", "Swamp", "Mountain", "Forest"]), ans )
    for (i, elem) in pairs(ans)
        if haskey(multicard_synonyms, elem[1])
            ans[i] = (multicard_synonyms[elem[1]], elem[2])
        end
    end
    ans
end

function deckreader_tsv(file)
    lines = readlines(file)
    filter!( x -> occursin(r"^\s*\d+", x), lines)
    matches = eachmatch.(Ref(r"\t"), lines)
    matches = map(x -> [y.offset for y in x], matches)
    end_of_name = [
        length(matches[i]) >= 2 ? matches[i][2] : length(lines[i]) for i in eachindex(lines)
    ]
    end_of_count = [
        x[1] for x in matches
    ]
    count = [ parse_max_4(lines[i][1:(end_of_count[i])]) for i in eachindex(lines) ]
    name = [ String(strip(lines[i][end_of_count[i]:end_of_name[i]])) for i in eachindex(lines) ]

    ans = collect(zip(name, count))
    filter!(x -> !in(x[1], ["Plains", "Island", "Swamp", "Mountain", "Forest"]), ans )
    for (i, elem) in pairs(ans)
        if haskey(multicard_synonyms, elem[1])
            ans[i] = (multicard_synonyms[elem[1]], elem[2])
        end
    end
    ans
end

function parse_max_4(x)
    ans = parse(Int, x)
    if ans > 4
        ans = 4
    end
    ans
end
