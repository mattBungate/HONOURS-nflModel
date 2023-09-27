using DataFrames
using CSV 
using Distributions

include("util/state.jl")
include("util/constants.jl")
include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")

"""
Finds the optimal action given a state and returns that action and the expected value if taken. 

Parameters:
time_remaining: How many plays remaining in game
score_diff: Difference of scores between teams (team - opp)
clock_ticking: 1 if clock ticking, 0 if not 
ball_position: 0-99 value for dist to goal. This is rounded in function to a section
down: 0,1,2,4 for what down the play is on
first_down_position: 0-99 value for how far first down is from ball. This will be rounded in function to a section
"""
function state_value(
    state:: State
)
    # Base cases
    if state.plays_remaining <= 0
        # First half maximise points
        if Bool(state.is_first_half)
            return state.score_diff, "End 1st half"
        end
        # Second half maximise winning
        if state.score_diff > 0
            return 100, "End Game"
        elseif score_diff == 0
            return 50, "End Game"
        else
            return 0, "End Game"
        end
    end

    if haskey(state_values, state)
        return state_values[state]
    end
    
    # Initialise arrays to store action space and associated values
    action_space = Dict{String, Float64}()

    # Field goal attempt value
    ball_section = state.ball_section
    col_name = Symbol("T-$ball_section")
    field_goal_prob = field_goal_df[1, col_name]
    if field_goal_prob > PROB_TOL
        field_attempt_val = field_goal_attempt(
            state,
            field_goal_prob
        )
        action_space["Field Goal"] = field_attempt_val
    end
    
    # Punt Decision
    punt_val = punt_value(state)
    action_space["Punt"] = punt_val

    # No timeout calculation
    no_timeout_stats = filter(row ->
        (row[:"Down"] == state.down) &
        (row[:"Field Section"] == state.ball_section) &
        (row[:"Timeout Used"] == 0),
        transition_df
    )
    if nrow(no_timeout_stats) > 0
        no_timeout_value = play_value(
            state,
            no_timeout_stats,
            false
        )
        action_space["Play No Timeout"] = no_timeout_value
    end

    # Timeout calculations
    if state.timeouts_remaining > 0 && Bool(state.offense_has_ball)     # Only allow timeout for offense if timeouts available
        # Retrieve the row for prob of down, position & timeout
        timeout_stats = filter(row ->
            (row[:"Down"] == state.down) &
            (row[:"Field Section"] == state.ball_section) &
            (row[:"Timeout Used"] == 1),
            transition_df
        )
        # Check if we have stats for state 
        if nrow(timeout_stats) > 0
            timeout_value = play_value(
                state,
                timeout_stats,
                true
            )
            action_space["Play Timeout"] = timeout_value
        end
    end
    
    # Get the optimal action and its value
    optimal_decision = findmax(action_space)

    # Store the optimal decision
    state_values[state] = optimal_decision

    return optimal_decision
end


# Data
transition_df = CSV.File("processed_data/stats.csv") |> DataFrame 
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_stats.csv") |> DataFrame
punt_dist = Normal(punt_df[1, :"Mean"], punt_df[1, :"Std"])

# Inputs
plays_remaining = 6
score_diff = 0
timeouts_remaining = 3
ball_position = 3
down = 1
first_down_dist = 10
offense_has_ball = 1
is_first_half = 1

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
