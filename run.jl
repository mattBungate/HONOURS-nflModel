using DataFrames
using CSV
using Distributions

include("util/state.jl")
include("util/constants.jl")
include("util/util.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")
include("actions/spike_handling.jl")
include("actions/timeout_handling.jl")
include("tests/real_tests.jl")
include("tests/run_tests.jl")
include("state_value_calc.jl")
include("interpolation.jl")
include("evaluate_game.jl")
include("order_actions.jl")

action_space = ["Kneel", "Punt", "Delayed Play", "Delayed Timeout", "Field Goal", "Timeout", "Hurried Play", "Spike"]
action_functions = Dict{String,Function}(
    "Kneel" => kneel_value_calc,
    "Timeout" => immediate_timeout_value_calc,
    "Delayed Timeout" => delayed_timeout_value_calc,
    "Field Goal" => field_goal_value_calc,
    "Punt" => punt_value_calc,
    "Hurried Play" => hurried_play_action_calc,
    "Delayed Play" => delayed_play_action_calc,
    "Spike" => spike_value_calc
)

function solve_DFS(
    initial_state::State,
    initial_depth::Int,
    depth_step::Int
)
    best_move = ""
    best_value = -Inf
    """
    for depth in initial_depth:depth_step:initial_state.seconds_remaining
        try
            empty!(state_values)
            seconds_cutoff = initial_state.seconds_remaining - depth
            search_output = state_value_calc(initial_state, true, best_move)
            best_value = search_output[1]
            best_move = search_output[2]
            println("\nSearch depth: depth")
            println("Best move: best_move")
            println("States stored: (length(state_values))\n")
        catch e
            if isa(e, InterruptException)
                println("We found our interrupt exception")
                println("Our best move is: best_move")
            end
            rethrow()
        end
    end
    """
    output = state_value_calc(initial_state, true, "")
    return output
end


global state_value_calc_calls = 0
global interpolated_value_calls = 0



const IS_FIRST_HALF = false # TODO: Have a way to have this as an input

# Order from easiest to hardest: 4, 8, 11, 10, 6, 7
test_case = REAL_TESTS[4]
test_state = test_case[1]
test_action = test_case[2]
"""
State:
- Seconds remaining
- Score differential
- Timeouts remaining
- Ball position
- Down
- First down dist
- Clock ticking
"""
dummy_test_state = State(
    16,
    test_state.score_diff,
    test_state.timeouts_remaining,
    50,
    4,
    1,
    test_state.clock_ticking
)
#println(REAL_TEST_DESCRIPTION[11])

const starting_score_diff = test_state.score_diff
const SCORE_BOUND = 14


function run_with_timeout(func::Function, timeout_seconds::Int, state::State, initial_depth::Int, depth_step::Int)
    @sync begin
        task = @async begin
            try
                func(state, initial_depth, depth_step)
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

interpolated_value_calls = 0
global state_values = Dict{State, Tuple{Float64, String}}()

println("Test state: $(dummy_test_state)")

#play_outcomes = delayed_play_outcome_space(dummy_test_state)
#punt_outcomes = punt_outcome_space(dummy_test_state)