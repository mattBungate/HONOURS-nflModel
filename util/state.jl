"""
Struct to hold the information for the state

Fields:
- plays_remaining: how many plays until the clock expires
- score_diff: Difference of scores between teams (team - opp)
- timeouts_remaining: Timeouts remaining (off, def)
- ball_section: Section of the field the ball is in
- down: What down it is
- first_down_section: Field section that must be reach to achieve first down
- clock_ticking: Game clock ticking after play ends 
- is_first_half: First or second half 
"""

struct State
    plays_remaining::Int
    score_diff::Int
    timeouts_remaining::Tuple{Int,Int}
    ball_section::Int
    down::Int
    first_down_section::Int
    timeout_called::Bool
    clock_ticking::Bool
    is_first_half::Bool
end