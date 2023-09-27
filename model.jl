using DataFrames
using CSV 
using Distributions

include("actions/punt_handling.jl")
include("actions/field_goal_handling.jl")
include("actions/play_handling.jl")

"""
Runs a play and returns position value and optimal play. 

Parameters:
time_remaining: How many plays remaining in game
score_diff: Difference of scores between teams (team - opp)
clock_ticking: 1 if clock ticking, 0 if not 
ball_position: 0-99 value for dist to goal. This is rounded in function to a section
down: 0,1,2,4 for what down the play is on
first_down_position: 0-99 value for how far first down is from ball. This will be rounded in function to a section
"""
function run_play(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool
)
    # Base cases
    if time_remaining <= 0
        # First half maximise points
        if is_first_half
            return score_diff, "End 1st half"
        end
        # Second half maximise winning
        if score_diff > 0
            return 100, "End Game"
        elseif score_diff == 0
            return 50, "End Game"
        else
            return 0, "End Game"
        end
    end
    
    # Round ball_position & first_down_position to field sections
    ball_section = Int(ceil(ball_position/10))
    first_down_section = Int(ceil((first_down_position+ball_section)/10) + 1) # Must reach at least first down. +1 ensure this happens 

    if offense_has_ball
        offense_flag = 1
    else
        offense_flag = 0
    end

    if is_first_half
        first_half_flag = 1
    else
        first_half_flag = 0
    end

    if haskey(position_val_dict, [time_remaining, score_diff, timeouts_remaining, ball_section, first_down_position, offense_flag, first_half_flag])
        return position_val_dict[
            time_remaining,
            score_diff,
            timeouts_remaining, 
            ball_section,
            first_down_position,
            offense_flag,
            first_half_flag
        ]
    end
    
    # Initialise arrays to store action space and associated values
    action_space = Dict{String, Float64}()

    # Field goal attempt value
    col_name = Symbol("T-$ball_section")
    field_goal_prob = field_goal_df[1, col_name]
    if field_goal_prob > PROB_TOL
        field_attempt_val = field_goal_attempt(
            time_remaining,
            score_diff,
            timeouts_remaining,
            ball_position,
            down,
            first_down_position,
            offense_has_ball,
            is_first_half,
            field_goal_prob
        )
        action_space["Field Goal"] = field_attempt_val
    end
    
    # Punt Decision
    punt_val = punt_value(
        time_remaining::Int,
        score_diff::Int,
        timeouts_remaining::Int,
        ball_position::Int,
        down::Int,
        first_down_position::Int,
        offense_has_ball::Bool,
        is_first_half::Bool
    )
    action_space["Punt"] = punt_val

    # No timeout calculation
    no_timeout_stats = filter(row ->
        (row[:"Down"] == down) &
        (row[:"Field Section"] == ball_section) &
        (row[:"Timeout Used"] == 0),
        transition_df
    )
    dummy_transition_prob = no_timeout_stats[1, Symbol("T-1")]
    if !ismissing(dummy_transition_prob)
        no_timeout_value = play_value(
            time_remaining,
            score_diff,
            timeouts_remaining,
            ball_position,
            down,
            first_down_section,
            offense_has_ball,
            is_first_half,
            no_timeout_stats
        )
        action_space["Play No Timeout"] = no_timeout_value
    end
    # Timeout calculations
    if timeouts_remaining > 0 && offense_has_ball # Only allow timeout for offense if timeouts available
        # Retrieve the row for prob of down, position & timeout
        timeout_stats = filter(row ->
            (row[:"Down"] == down) &
            (row[:"Field Section"] == ball_section) &
            (row[:"Timeout Used"] == 1),
            transition_df
        )
        # Check if we have stats for state 
        dummy_transition_prob = timeout_stats[1, Symbol("T-1")]
        if !ismissing(dummy_transition_prob)
            timeout_value = play_value(
                time_remaining,
                score_diff,
                timeouts_remaining,
                ball_position,
                down,
                first_down_section,
                offense_has_ball,
                is_first_half,
                timeout_stats
            )
            action_space["Play Timeout"] = timeout_value
        end
    end
    
    # Get the optimal action and its value and return
    optimal_decision = findmax(action_space)
    return optimal_decision
end


# Data
transition_df = CSV.File("processed_data/stats.csv") |> DataFrame 
field_goal_df = CSV.File("processed_data/field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("processed_data/punt_stats.csv") |> DataFrame
punt_dist = Normal(punt_df[1, :"Mean"], punt_df[1, :"Std"])

# Constants
possible_downs = [1,2,3,4]
field_sections = [0,1,2,3,4,5,6,7,8,9,10,11]
PROB_TOL = 1.0e-8

# Inputs
plays_remaining = 1
score_diff = 0
timeouts_remaining = 3
ball_position = 95
down = 4
first_down_dist = 5
offense_has_ball = true
is_first_half = true 

position_val_dict = Dict{Vector{Int}, Tuple{Float64, String}}()

println("Plays remaining: $plays_remaining")
@time play_value_calc = run_play(
    plays_remaining,        # Plays remaining 
    score_diff,             # Score diff 
    timeouts_remaining,     # Timeouts remaining 
    ball_position,          # Ball position 
    down,                   # Down 
    first_down_dist,        # First down section
    offense_has_ball,       # Offense has ball
    is_first_half           # First/second half
)

play_value_rounded = round(play_value_calc[1], digits=2)
play_type = play_value_calc[2]

if is_first_half
    println("\n\nThe expected score differential for this position if played optimally is $play_value_rounded")
else
    println("\n\nThere is a $play_value_rounded % chance of winning in this position")
end
println("Optimal play: $play_type\n\n")
