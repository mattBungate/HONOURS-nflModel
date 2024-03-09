function get_feasible_actions(
    state::PlayState
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

function order_actions(
    state::PlayState,
    best_move::String
)::Vector{String}
    feasible_actions = get_feasible_actions(state)

    action_space_ordered = []
    if state.score_diff > 0
        for action in feasible_actions
            if action in feasible_actions
                push!(action_space_ordered, action)
            end
        end
    else
        for action in reverse(action_space)
            if action in feasible_actions
                push!(action_space_ordered, action)
            end
        end
    end

    # Move best move to front 
    if best_move == ""
        return action_space_ordered
    else
        ordered_moves = [best_move]
        for action in action_space
            if action == best_move
                continue
            end
            push!(ordered_moves, action)
        end
        return ordered_moves
    end
end