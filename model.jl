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

"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value_calc(
    state::State
)
    global state_value_calc_calls
    state_value_calc_calls += 1
    # Base cases
    if state.seconds_remaining <= 0
        # 1st half: maximise points
        if state.is_first_half
            return state.score_diff, "End 1st half"
        end
        # 2nd half: maximise winning
        if state.score_diff > 0
            return 1, "End Game"
        elseif state.score_diff == 0
            return 0, "End Game"
        else
            return -1, "End Game"
        end
    end

    # Check if state is cached
    if haskey(state_values, state)
        return state_values[state]
    end

    # Initialise arrays to store action space and associated values
    action_values = Dict{String,Float64}()

    # Order the actions
    if state.score_diff > 0
        action_space_ordered = action_space
    else
        action_space_ordered = reverse(action_space)
    end

    optimal_value::Union{Nothing,Float64} = nothing

    # Iterate through each action in action_space
    for action in action_space_ordered
        #println("Checking play: $action")
        # Calculate action value
        if action == "Timeout"
            action_value = action_functions[action](state, false, optimal_value) # Clean this up
        elseif action == "Delayed Timeout"
            action_value = action_functions[action](state, true, optimal_value) # Clean this up
        else
            action_value = action_functions[action](state, optimal_value)
        end
        # Store action value if value returned        
        if action_value !== nothing
            action_values[action] = action_value
            if optimal_value === nothing || optimal_value < action_value
                #println("Replacing optimal value $(optimal_value) with $(action_value)")
                optimal_value = action_value
            end
        end
    end

    # Find optimal action
    optimal_action = findmax(action_values)

    # Store all states
    state_values[state] = optimal_action

    return optimal_action
end

global state_value_calc_calls = 0

# Data
play_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_probs.csv") |> DataFrame
time_df = CSV.File("processed_data/time_stats_2022.csv") |> DataFrame
time_punt_df = CSV.File("processed_data/punt_time_stats_2022.csv") |> DataFrame
time_field_goal_df = CSV.File("processed_data/field_goal_time_2022.csv") |> DataFrame

# Inputs
seconds_remaining = 2
score_diff = 0
timeouts_remaining = (3, 0)
ball_position = TOUCHBACK_SECTION
down = 1
first_down_dist = TOUCHBACK_SECTION + FIRST_DOWN_TO_GO
timeout_called = false
clock_ticking = true
is_first_half = false

action_space = ["Kneel", "Timeout", "Delayed Timeout", "Field Goal", "Punt", "Play", "Spike"]

action_functions = Dict{String,Function}(
    "Kneel" => kneel_value_calc,
    "Timeout" => timeout_value_calc,
    "Delayed Timeout" => timeout_value_calc,
    "Field Goal" => field_goal_value_calc,
    "Punt" => punt_value_calc,
    "Play" => play_value_calc,
    "Spike" => spike_value_calc
)

state_values = Dict{State,Tuple{Float64,String}}()

initial_state = State(
    seconds_remaining,
    score_diff,
    timeouts_remaining,
    ball_position,
    down,
    first_down_dist,
    timeout_called,
    clock_ticking,
    is_first_half
)
println("Initial state:")
println(initial_state)

println("Seconds remaining: $seconds_remaining")
@time state_value = state_value_calc(
    initial_state
)
println(length(state_values))
println("Number of state value function calls: $(state_value_calc_calls)")

state_value_rounded = round(state_value[1], digits=2)
play_type = state_value[2]

if Bool(is_first_half)
    println("\n\nThe expected score differential for this position if played optimally is $state_value_rounded")
else
    println("\n\nThere is a $state_value_rounded % chance of winning in this position")
end
println("Optimal play: $play_type\n\n")


println("Test haskey function")
@time dummy_var = haskey(state_values, initial_state)
