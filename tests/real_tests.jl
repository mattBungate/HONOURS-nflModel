

MNV_KC_WK5_2023_1 = 1
MNV_KC_WK5_2023_2 = 2
LV_PIT_WK3_2023 = 3
SEA_PAT_SB_2015 = 4
JAX_NO_WK7_2023_1 = 5
JAX_NO_WK7_2023_2 = 6
JAX_NO_WK7_2023_3 = 7
JAX_NO_WK7_2023_4 = 8

"""
States of interesting plays in real games
Key: GAME ID
Value: State object of state of game
"""
REAL_TESTS = Dict{Int,Tuple{PlayState,Bool,String}}(
    1 => (
        PlayState(
            296,
            -7,
            (0, 3),
            81,
            4,
            7,
            true
        ),
        false,
        "Delay of Game Penalty"
    ),
    2 => (
        PlayState(
            296,
            -7,
            (0, 3),
            76,
            4,
            12,
            true
        ),
        false,
        "Pass"
    ),
    3 => (
        PlayState(
            145,
            -8,
            (3, 2),
            92,
            4,
            4,
            false
        ),
        false,
        "Field Goal"
    ),
    4 => (
        PlayState(
            26,
            -4,
            (2, 2),
            99,
            2,
            1,
            true
        ),
        false,
        "Pass"
    ),
    5 => (
        PlayState(
            245,
            -11,
            (3, 3),
            61,
            4,
            3,
            true
        ),
        true,
        "Pass"
    ),
    6 => (
        PlayState(
            93,
            8,
            (3, 3),
            54,
            4,
            2,
            true
        ),
        true,
        "Defenseive Timeout"
    ),
    7 => (
        PlayState(
            93,
            8,
            (3, 2),
            54,
            4,
            2,
            false
        ),
        true,
        "Fake Punt. Completed Pass"
    ),
    8 => (
        PlayState(
            36,
            8,
            (3, 2),
            75,
            4,
            2,
            true
        ),
        true,
        "Field Goal. Made."
    ),
    9 => (
        PlayState(
            103,
            -7,
            (3, 3),
            82,
            1,
            10,
            true
        ),
        false,
        "Pass. Incomplete"
    ),
    10 => (
        PlayState(
            83,
            -7,
            (3, 3),
            90,
            3,
            2,
            true
        ),
        false,
        "Run. Made first down"
    ),
    11 => (
        PlayState(
            62,
            -7,
            (3, 3),
            94,
            1,
            6,
            true
        ),
        false,
        "Pass. Incomplete"
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
    4 => "Pass",
    5 => "Pass",
    6 => "Defensive timeout",
    7 => "Fake punt. Pass",
    8 => "Field Goal. Made",
    9 => "Pass. Incomplete",
    10 => "Run. Made first down",
    11 => "Pass. Incomplete"
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
    4 => "4th & 1. Pass. Intercepted. Lost Superbowl.",
    5 => "4th & 3. ",
    6 => "4th & 2. Could go for it or punt. NO called defensive timeout",
    7 => "4th & 2. Can go for it or punt. Fake punt. Pass completed.",
    8 => "4th & 2 36s left. Kicked field goal. Could've gone for it. ",
    9 => "1st & 10. Just made first down. 1:34 clock. No timeout. No huddle. 10 seconds to get off play. Pass incomplete",
    10 => "3rd & 2. Clock ticking. No timeout called. Run play. Made first down",
    11 => "IDK. Dont remember. Go find" # TODO: Find & write description
)