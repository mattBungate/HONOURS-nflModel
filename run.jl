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
include("actions/action_value_calc.jl")
include("tests/real_tests.jl")
include("tests/run_tests.jl")
include("state_value_calc.jl")
include("interpolation.jl")
include("evaluate_game.jl")
include("order_actions.jl")

action_space = ["Kneel", "Punt", "Delayed Play", "Delayed Timeout", "Field Goal", "Timeout", "Hurried Play", "Spike"]

generate_outcome_space = Dict{String, Function}(
    "Kneel" => kneel_outcome_space,
    "Timeout" => immediate_timeout_outcome_space,
    "Delayed Timeout" => delayed_timeout_outcome_space,
    "Field Goal" => field_goal_outcome_space,
    "Punt" => punt_outcome_space,
    "Hurried Play" => hurried_play_outcome_space,
    "Delayed Play" => delayed_play_outcome_space,
    "Spike" => spike_outcome_space
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

for seconds in 1:20
    for timeouts_remaining in 0:3

        dummy_test_state = State(
            seconds,
            test_state.score_diff,
            (timeouts_remaining, timeouts_remaining),
            85,
            4,
            1,
            true
        )

        global state_values = Dict{State, Tuple{Float64, String}}()
        global function_calls = 0 

        println("\nSeconds: $(seconds)s | Timeouts: ($(timeouts_remaining), $(timeouts_remaining))")

        start_time = time()
        optimal_value, optimal_action = state_value_calc(dummy_test_state, true, "")
        end_time = time()
        duration = end_time - start_time

        println("Cached states: $(length(state_values))")
        println("Optimal action: $(optimal_action) ($(optimal_value))")
        println("Solve time: $(duration)s")
    end
end