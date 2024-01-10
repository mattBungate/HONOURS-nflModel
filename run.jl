using DataFrames
using CSV
using Distributions

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
include("state_value_calc.jl")
include("interpolation.jl")
include("evaluate_game.jl")

"""
function solve_MCTS(
    initial_state::State
)
    while true
        try 
            # 1. Selection (using formula)
            # 2. Expansion (Randomly choose an outcome from outcome space. If already explored continue)
            # 3. Simulation (Create node for new state. Randomly choose action. Randomly choose outcome from each action. Additionally can "inform" the play)
            # 4. Backpropogation (Iterate through all parent nodes recursively, incrementing total score and times visited)
        catch e
            if isa(e, InterruptException)
                # Sort through all the actions and see what is the best action
    end
end
"""

global state_value_calc_calls = 0
global interpolated_value_calls = 0





function run_with_timeout(
    func::Function, 
    state::State)
    @sync begin
        task = @async begin
            try
                func(state)
            catch e
                println("Task interrupted or an error occurred: $e")
            finally
                println("We are now exiting the @async block")
                yield()
            end
        end
        sleep(timeout_seconds)
        schedule(task, InterruptException(), error=true)
    end
    println("Exiting improved_run_with_timeout")
end


const IS_FIRST_HALF = false # TODO: Have a way to have this as an input

# Order from easiest to hardest: 4, 8, 11, 10, 6, 7
test_case = REAL_TESTS[4]
test_state = test_case[1]
test_action = test_case[2]
#println(REAL_TEST_DESCRIPTION[11])
dummy_test_state = State(
    test_state.seconds_remaining,
    test_state.score_diff,
    (0, 3),
    60,
    4,
    test_state.first_down_dist,
    test_state.clock_ticking
)

const starting_score_diff = test_state.score_diff
const SCORE_BOUND = 14

println("Testing: $dummy_test_state")
delayed_states = delayed_play_children(dummy_test_state)
println("Number of children for delayed play: $(length(delayed_states))")