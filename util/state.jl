"""
Struct to hold the information for the state

Fields:
- plays_remaining: how many plays until the clock expires
- score_diff: Difference of scores between teams (team - opp)
- timeouts_remaining: How many timeouts the team has
- ball_section: Section of the field the ball is in
- 
"""
struct State
    plays_remaining:: Int
    score_diff:: Int
    timeouts_remaining:: Int
    ball_section:: Int
    down:: Int
    first_down_dist:: Int
    offense_has_ball:: Int
    is_first_half:: Int
end