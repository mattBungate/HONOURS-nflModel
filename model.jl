using DataFrames
using CSV 
using Distributions

"""
Runs a field goal attempt and returns the position value considering the outcomes
"""
function field_goal_attempt(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool
)
    field_goal_value = 0
    # field goal probability
    ball_section = Int(ceil(ball_position/10))
    col_name = Symbol("T-$ball_section")
    field_goal_prob = field_goal_df[1, col_name]
    # Kick field goal prob
    if field_goal_prob > PROB_TOL
        field_goal_made_val = field_goal_prob * run_play(
            Int(time_remaining-1),
            Int(score_diff + 3), 
            timeouts_remaining,
            25,
            1,
            10,
            !offense_has_ball, 
            is_first_half
        )[1]
        if ball_section < 10
            field_goal_missed_val = (1-field_goal_prob) * run_play(
                Int(time_remaining-1),
                score_diff,
                timeouts_remaining,
                Int(100 - 10*ball_section-5),
                1,
                10,
                !offense_has_ball,
                is_first_half
            )[1]
        else
            field_goal_missed_val = (1-field_goal_prob)*run_play(
                Int(time_remaining-1),
                score_diff,
                timeouts_remaining,
                20,
                1,
                10,
                !offense_has_ball,
                is_first_half
            )[1]
        end
    else
        # This is not right
        field_goal_made_val = 0
        if ball_section < 10
            field_goal_missed_val = run_play(
                Int(time_remaining-1),
                score_diff,
                timeouts_remaining,
                Int(100 - 10*ball_section-5),
                1,
                10,
                !offense_has_ball,
                is_first_half
            )[1]
        else
            field_goal_missed_val = run_play(
                Int(time_remaining-1),
                score_diff,
                timeouts_remaining,
                20,
                1,
                10,
                !offense_has_ball,
                is_first_half
            )[1]
        end
    end
    field_goal_value = field_goal_missed_val + field_goal_made_val 
    return field_goal_value
end

function punt_value(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool
)
    punt_val = 0

    ball_section = Int(ceil(ball_position/10))

    section_probs = []
    for end_section in field_sections
        if end_section == 0
            push!(section_probs, cdf(punt_dist, -ball_section*10 + 5))
        elseif end_section == 11
            section_probs[8+1] += 1 - cdf(punt_dist, 10*(11-ball_section)-5) # If punt goes into end zone its an atuo touchback
        else
            push!(section_probs, cdf(punt_dist, 10*(end_section-ball_section) + 5) - cdf(punt_dist, 10*(end_section-ball_section)-5))
        end
    end

    for end_section in 0:10
        if section_probs[end_section + 1] > PROB_TOL
            if end_section == 0 # If other team scores off punt return
                punt_val += section_probs[1] * run_play(
                    Int(time_remaining - 1),
                    offense_has_ball ? Int(score_diff - 7) : Int(score_diff + 7), 
                    timeouts_remaining,
                    25, # Assumes touchback from kickoff
                    1, 
                    10,
                    offense_has_ball,
                    is_first_half
                )[1]
            else
                punt_val += section_probs[end_section + 1] * run_play(
                    Int(time_remaining - 1),
                    score_diff, 
                    timeouts_remaining,
                    end_section,
                    1,
                    10,
                    !offense_has_ball,
                    is_first_half
                )[1]
            end
        end
    end

    return punt_val
end

function play_value(
    time_remaining::Int,
    score_diff::Int,
    timeouts_remaining::Int,
    ball_position::Int,
    down::Int,
    first_down_position::Int,
    offense_has_ball::Bool,
    is_first_half::Bool,

    probabilities::DataFrame
)
    play_value = 0

    ball_section = Int(ceil(ball_position/10))
    first_down_section = ceil((first_down_position+ball_section)/10) + 1 

    for section in 1:10
        col_name = Symbol("T-$section")
        transition_prob = probabilities[1, col_name]
        # Calculate what down it is and where the next down is
        if section >= first_down_section
            next_first_down = section + 1
            next_down = 1
        else
            next_first_down = first_down_section 
            next_down = down + 1
        end
        if transition_prob > 0
            play_value += transition_prob * run_play(
                Int(time_remaining-1),
                score_diff,
                Int(timeouts_remaining-1),
                Int(10*section - 5),
                Int(next_down),
                10,
                down == 4 ? !offense_has_ball : offense_has_ball,
                is_first_half
            )[1]
        end
    end
    # Pick six scenario 
    pick_six_prob = probabilities[1,:"T-0"]
    if pick_six_prob > 0
        play_value += pick_six_prob * run_play(
            Int(time_remaining-1),
            offense_has_ball ? Int(score_diff-7) : Int(score_diff+7),
            Int(timeouts_remaining-1),
            25,
            1,
            10,
            down == 4 ? !offense_has_ball : offense_has_ball,
            is_first_half
        )[1]
    end
    # Touchdown scenario
    td_prob = probabilities[1,"T-11"]
    if td_prob > 0
        play_value += td_prob * run_play(
            Int(time_remaining-1),
            Int(score_diff+7),
            Int(timeouts_remaining-1),
            25,
            1,
            10,
            down == 4 ? !offense_has_ball : offense_has_ball, # Changes team that has ball is 4th down
            is_first_half
        )[1]
    end
    return play_value
end


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
    first_down_section = ceil((first_down_position+ball_section)/10) + 1 # Must reach at least first down. +1 ensure this happens 
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
    
    # Field goal attempt value
    field_attempt_val = field_goal_attempt(
        time_remaining::Int,
        score_diff::Int,
        timeouts_remaining::Int,
        ball_position::Int,
        down::Int,
        first_down_position::Int,
        offense_has_ball::Bool,
        is_first_half::Bool
    )
    
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

    # No timeout calculation
    no_timeout_stats = filter(row ->
        (row[:"Down"] == down) &
        (row[:"Field Section"] == ball_section) &
        (row[:"Timeout Used"] == 0),
        transition_df
    )
    no_timeout_value = play_value(
        time_remaining,
        score_diff,
        timeouts_remaining,
        ball_position,
        down,
        first_down_position,
        offense_has_ball,
        is_first_half,
        no_timeout_stats
    )
    # Timeout calculations
    timeout_value = 0 # this is also wrong. If all other decisions have negative play value, this would be max
    if timeouts_remaining > 0 && offense_has_ball # Only allow timeout for offense if timeouts available
        # Retrieve the row for prob of down, position & timeout
        timeout_stats = filter(row ->
            (row[:"Down"] == down) &
            (row[:"Field Section"] == ball_section) &
            (row[:"Timeout Used"] == 1),
            transition_df
        )
        timeout_value = play_value(
            time_remaining,
            score_diff,
            timeouts_remaining,
            ball_position,
            down,
            first_down_position,
            offense_has_ball,
            is_first_half,
            timeout_stats
        )
    end
    
    # Get the optimal decision and return position value & optimal decision
    """
    println("Decision values")
    println("Punt_value: $punt_val")
    println("Field Goal value: $field_attempt_val")
    println("Play (no timeout): $no_timeout_value")
    println("Play (timeout): $timeout_value\n")
    """
    position_value, decision_index = findmax([punt_val, field_attempt_val, no_timeout_value, timeout_value])
    return position_value, decisions[decision_index]
end


# Data
transition_df = CSV.File("stats.csv") |> DataFrame 
field_goal_df = CSV.File("field_goal_stats.csv") |> DataFrame
punt_df = CSV.File("punt_stats.csv") |> DataFrame
punt_dist = Normal(punt_df[1, :"Mean"], punt_df[1, :"Std"])

position_val_dict = Dict{Vector{Int}, Tuple{Float64, String}}()

# Constants
possible_downs = [1,2,3,4]
field_sections = [0,1,2,3,4,5,6,7,8,9,10,11]
decisions = ["Punt", "Field Goal", "No timeout", "Timeout"]
PROB_TOL = 1.0e-8

# Inputs
plays_remaining = 3
score_diff = 0
timeouts_remaining = 3
ball_position = 25
down = 1
first_down_dist = 10
offense_has_ball = true
is_first_half = true 

#println("Plays remaining: $plays_remaining")
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