using DataFrames
using CSV 
using Distributions

include("util/state.jl")
include("util/constants.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")
include("actions/kneel_handling.jl")

"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
state: State space currently occupied.
"""
function state_value(
    state:: State
)
    # Base cases
    if state.plays_remaining <= 0
        if Bool(state.is_first_half)
            # 1st half: Maximise points
            return state.score_diff
        else
            # 2nd half: Maximise win chance
            if state.score_diff > 0
                return 1
            elseif state.score_diff == 0
                return 0.5
            else
                return 0
            end
        end
    end

    # Check score to see if we want to be risky or risk-averse
    action_space_vals = Dict{String, Float64}()

    if state.score_diff > 0
        actions_ordered = actions
    else
        actions_ordered = reverse(actions)
    end

    for action in actions_ordered
        if action == "Play Timeout"
            action_value = action_funcs[action](state, true)
        elseif action == "Play No Timeout"
            action_value = action_funcs[action](state, false)
        else
            action_value = action_funcs[action](state)
        end
        if action_value !== nothing
            action_space_vals[action] = action_value
        end
    end

    # Get optimal
    optimal_decision = findmax(action_space_vals)

    # Store solution
    state_values[state] = optimal_decision

    return optimal_decision
end

# Data
transition_df = CSV.File("processed_data/stats_1_yard_sections.csv") |> DataFrame 
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_stats.csv") |> DataFrame
punt_dist = Normal(punt_df[1, :"Mean"], punt_df[1, :"Std"])

# Actions ordered in terms of risk (least to most)
actions = ["Kneel", "Punt", "Field Goal", "Play Timeout", "Play No Timeout"]

action_funcs = Dict{String, Function}(
    "Kneel" => kneel_calc,
    "Punt" => punt_value,
    "Field Goal" => field_goal_attempt,
    "Play Timeout" => play_value,
    "Play No Timeout" => play_value
)

# Inputs
plays_remaining = 2
score_diff = 1
timeouts_remaining = 3
ball_position = TOUCHBACK_SECTION
down = 1
first_down_dist = TOUCHBACK_SECTION + FIRST_DOWN_TO_GO
offense_has_ball = 1
is_first_half = 0

initial_state = State(
    plays_remaining,
    score_diff,
    timeouts_remaining,
    ball_position,
    down,
    first_down_dist,
    offense_has_ball,
    is_first_half
)

state_values = Dict{State, Tuple{Float64, String}}()

println("Plays remaining: $plays_remaining")
@time play_value_calc = state_value(
    initial_state
)
println(length(state_values))

play_value_rounded = round(play_value_calc[1], digits=2)
play_type = play_value_calc[2]

if Bool(is_first_half)
    println("\n\nThe expected score differential for this position if played optimally is $play_value_rounded")
else
    println("\n\nThere is a $play_value_rounded % chance of winning in this position")
end
println("Optimal play: $play_type\n\n")
