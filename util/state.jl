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
    seconds_remaining::Int
    score_diff::Int
    timeouts_remaining::Tuple{Int,Int}
    ball_section::Int
    down::Int
    first_down_dist::Int
    clock_ticking::Bool
end

# Set up printing state object
function Base.show(io::IO, s::State)
    print(
        io,
        "State(
    Seconds remaining: $(s.seconds_remaining)
    Score differential: $(s.score_diff)
    Timeouts remaining: $(s.timeouts_remaining)
    Ball section: $(s.ball_section)
    Down: $(s.down)
    First down section: $(s.first_down_dist)
    Clock ticking: $(s.clock_ticking ? "Y" : "N")
)"
    )
end