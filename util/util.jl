"""
Random functions

Mostly small functions that I've renamed for readability sake in the model
"""
function flip_field(ball_section)
    return TOUCHDOWN_SECTION - ball_section
end

function get_feasible_actions(
    state::State
)::Vector{String}
    feasible_actions = []
    if state.ball_section > FIELD_GOAL_CUTOFF
        push!(feasible_actions, "Field Goal")
    end
    if state.down != 4
        if state.clock_ticking
            push!(feasible_actions, "Kneel")
            push!(feasible_actions, "Spike")
        end
    elseif state.ball_section < flip_field(TOUCHBACK_SECTION)
        push!(feasible_actions, "Punt")
    end
    if state.timeouts_remaining[1] > 0 && state.clock_ticking
        push!(feasible_actions, "Timeout")
        if state.seconds_remaining > 1
            push!(feasible_actions, "Delayed Timeout")
        end
    end
    push!(feasible_actions, "Hurried Play")
    if state.seconds_remaining > 1
        push!(feasible_actions, "Delayed Play")
    end
    
    return feasible_actions
end