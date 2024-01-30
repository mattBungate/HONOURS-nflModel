using DataFrames
using CSV
using Distributions
using Random

include("util/state.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")
include("actions/spike_handling.jl")
include("actions/timeout_handling.jl")
include("util/constants.jl")
include("util/util.jl")
include("tests/real_tests.jl")
include("tests/run_tests.jl")
include("MCTS_functions/MCTS_solve.jl")
include("MCTS_functions/node.jl")
include("MCTS_functions/MCTS_helper.jl")

# Order least to most seconds remaining: 
# 4, 8, 11, 10, 6, 7

const RANDOM = false

if !RANDOM
    Random.seed!(123)
end

run_tests(
    true,
    5,
    1000
)