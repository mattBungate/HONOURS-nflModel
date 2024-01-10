

mutable struct Node
    state::State
    times_visited::Int
    total_score::Int
    parents::Vector{Node} 
    parent_change_possesion::Vector{Bool}
    action_stats::Dict{String, Tuple{Int, Int}}
    visited_children::Dict{String, Node}
end
