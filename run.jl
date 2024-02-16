using DataFrames
using CSV
using Distributions
using Base: @sync, @async, Task

using Base.Threads: Atomic

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
#include("tests/real_tests.jl")
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
    initial_state::StateFH,
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
#test_case = REAL_TESTS[4]
#test_state = test_case[1]
#test_action = test_case[2]

#const starting_score_diff = test_state.score_diff
#const SCORE_BOUND = 14
"""
function run_with_timeout(
    func::Function, 
    timeout_seconds::Int, 
    state::State
)
    @sync begin
        task = @async begin
            try
                return func(state, true, "")
            catch e
                println("Task interrupted or an error occurred: e")
                rethrow()
                return -Inf, "Timed out"
            end
        end
        sleep(timeout_seconds)
        schedule(task, InterruptException(), error=true)
    end
end
"""



function run_with_timeout(func::Function, timeout_seconds::Int, state::StateFH)
    result = Ref{Any}((-Inf, "Timed out", -1))
    done = Channel{Bool}(1) # Channel to signal task completion
    stop_signal = Atomic{Bool}(false) # Shared signal to indicate stopping

    @sync begin
        @async begin
            try
                start_time = time()
                action_val, optimal_action = func(state, true, "", stop_signal) # func needs to accept stop_signal and check it
                end_time = time()
                if !stop_signal[]
                    result[] = (action_val, optimal_action, end_time - start_time) # Store result and execution time
                end
                # Signal completion by closing the channel, which also signals the timer task to stop waiting
                close(done)
            catch e
                println("Task interrupted or an error occurred: $e")
            end
        end

        @async begin
            sleep(timeout_seconds)
            if isopen(done) # Check if the channel is still open before attempting to signal
                stop_signal[] = true # Signal the function to stop
                try
                    put!(done, false) # Signal timeout, if the channel is still open
                catch e
                    # Channel might be closed if function completed just before timeout
                end
            end
        end
    end
    
    # Wait for either completion or timeout, but due to channel being closed by the func task,
    # this will immediately proceed if func finishes first.
    if isopen(done)
        take!(done) # This will only block if the done channel is still open and has not been taken or closed.
    end
    
    return result[]
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


test_state = State(
    1,
    0,
    (0,0),
    20,
    1,
    10,
    false
)




"""


#test_kickoff("first_half/interpolation")  

println("Done with testing kickoff. Next up is 2min kickoff situations:")
for timeouts_remaining in 0:3
    global state_values = Dict{StateFH, Tuple{Float64, String}}()
    global state_value_calc_calls = 0
    println("Calculating state value $(StateFH(
        120,
        (timeouts_remaining, timeouts_remaining),
        TOUCHBACK_SECTION,
        FIRST_DOWN,
        FIRST_DOWN_TO_GO,
        false
    ))")
    @time state_value_calc(
        StateFH(
            120,
            (timeouts_remaining, timeouts_remaining),
            TOUCHBACK_SECTION,
            FIRST_DOWN,
            FIRST_DOWN_TO_GO,
            false
        ),
        true,
        "",
        Atomic{Bool}(false)
    )
    
    println("Number of states stored: ($length(state_values))")
    println("Function calls: ($state_value_calc_calls)")
end