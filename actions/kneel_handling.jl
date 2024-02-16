
function kneel_outcome_space(
    state::StateFH
)::Vector{Tuple{StateFH, Float64, Int, Bool}} # State, prob, reward, change possession
    # Invalid action times
    if !state.clock_ticking
        return []
    end
    # Domain knowledge cutoff
    if state.down == 4
        return []
    end
    # State
    return [
        (
            StateFH(
                state.seconds_remaining - MAX_PLAY_CLOCK_DURATION,
                state.timeouts_remaining,
                state.ball_section,
                state.down + 1,
                state.first_down_dist,
                true
            ),
            1,
            0,
            false 
        )
    ]
end