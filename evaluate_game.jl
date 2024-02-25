

function evaluate_game(
    state::State
)
    if state.score_diff > 0
        return 1, "End Game"
    elseif state.score_diff == 0
        return 0, "End Game"
    else
        return -1, "End Game"
    end
end