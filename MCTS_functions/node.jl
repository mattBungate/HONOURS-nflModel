
"""
MCTS tree node.
"""
mutable struct Node
    state::State
    times_visited::Int
    total_score::Int
    parents::Vector{Node} 
    parent_change_possesion::Vector{Bool}
    action_stats::Dict{String, Tuple{Int, Int}} # Action -> (Score, Time visited)
    visited_children::Dict{String, Vector{Node}}
end

function create_child(
    parent_node::Node,
    parent_change_possesion::Bool,
    node_state::State
)
    feasible_actions = get_feasible_actions(node_state)

    action_stats = Dict{String, Tuple{Int, Int}}()
    visited_children = Dict{String, Vector{Node}}()
    for action in feasible_actions
        action_stats[action] = (0,0)
        visited_children = []
    end

    return Node(
        node_state,
        0,
        0,
        [parent_node],
        parent_change_possession,
        actions_stats,
        visited_children
    )
end