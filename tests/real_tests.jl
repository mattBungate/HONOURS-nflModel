

MNV_KC_WK5_2023_1 = 1
MNV_KC_WK5_2023_2 = 2
LV_PIT_WK3_2023 = 3
SS_PAT_SB_2015 = 4

"""
States of interesting plays in real games
Key: GAME ID
Value: State object of state of game
"""
REAL_TESTS = Dict{Int,Tuple{State,String}}(
    1 => (
        State(
            296,
            -7,
            (0, 3),
            81,
            4,
            88,
            false,
            true,
            false
        ),
        "Delay of Game Penalty"
    ),
    2 => (
        State(
            296,
            -7,
            (0, 3),
            76,
            4,
            88,
            false,
            true,
            false
        ),
        "Pass"
    ),
    3 => (
        State(
            145,
            -8,
            (3, 2),
            92,
            4,
            96,
            false,
            false,
            false
        ),
        "Field Goal"
    ),
    4 => (
        State(
            26,
            -4,
            (2, 2),
            99,
            2,
            TOUCHDOWN_SECTION,
            false,
            true,
            false
        ),
        "Pass"
    )
)
"""
Actions taken in game
key: GAME ID
value: Action
"""
REAL_TEST_ACTION = Dict{Int,String}(
    1 => "False Start Penalty Attempt",
    2 => "Pass",
    3 => "Field Goal",
    4 => "Pass"
)

"""
Description of states of games 
key: GAME ID
value: Description
"""
REAL_TEST_DESCRIPTION = Dict{Int,String}(
    1 => "4th & 7. Could have gone for Field Goal. Tried for false start penalty. Received delay of game penalty",
    2 => "4th & 12. Could have gone for Field Goal. Pass play. Deep right. Incomplete",
    3 => "4th & 4. Could have gone for it. Field Goal. Made",
    4 => "4th & 1. Pass. Intercepted. Lost Superbowl."
)