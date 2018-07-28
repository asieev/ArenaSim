export shufflesim

"""
    shufflesim(decks; kwargs...)

Simulates with batches of decks in a random order and then combines the output.

# Arguments
- `decks`: Vector of `Deckinfo` for the decks
- `shuffledecks`: A function to perform the shuffling for each batch.
- `parameters`: `SimParameters` for all simulations
- `sets`: Sets to simulate
- `reps`: Number of batches
- `batchsize`: Size of each batch

"""
function shufflesim(decks; shuffledecks = shuffle, parameters = SimParameters(),
     sets = sets, reps, batchsize)
    total_ouput = SimOutput( reps * batchsize,  length(decks), sets )

    deckinfos = deckinfo.(decks)

    index = 1
    for i = 1:reps
        simres = simulate(batchsize, shuffledecks(deckinfos), parameters = deepcopy(parameters), sets = sets)
        index = copy_into_output!(total_ouput, simres; startindex = index)
    end

    total_ouput
end
