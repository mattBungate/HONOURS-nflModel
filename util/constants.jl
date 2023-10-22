"""
All the constants that are used throughout this codebase
"""

const VERSION_NUM = "V_2_3_0"

const SECTION_WIDTH = 1                                     # Width of the sections

const FIELD_SECTIONS = [i for i in 0:100]                   # All field sections
const NON_SCORING_FIELD_SECTIONS = [i for i in 1:99]        # Field sections that aren't end zones
const TOUCHBACK_SECTION = 25                                # Touchback is 25yrd line (section 3)
const TOUCHDOWN_SECTION = 100                               # Scoring touchdown section
const TOUCHDOWN_CONCEEDED_SECTION = 0                       # Conceeding touchdown section
const FIELD_GOAL_MERCY_SECTION = 20                            # If a field goal inside this the ball is placed on the 25

const POSSIBLE_DOWNS = [1, 2, 3, 4]                            # All downs possible

const TOUCHDOWN_SCORE = 7                                   # Score of a touchdown
const FIELD_GOAL_SCORE = 3                                  # Score of a field goal

const FIRST_DOWN_TO_GO = 10                                 # Dist to first down if first down 
const FIRST_DOWN = 1                                        # For clarity

const PROB_TOL = 10e-8                                      # If prob is under its considered insignificant
const TIME_PROB_TOL = 10e-3

const KNEEL_DURATION = 40

const FIELD_GOAL_CUTOFF = 50

const MIN_PLAY_LENGTH = 1
const MAX_PLAY_LENGTH = 45

const MIN_FIELD_GOAL_DURATION = 1
const MAX_FIELD_GOAL_DURATION = 14

const MIN_PUNT_DURATION = 3
const MAX_PUNT_DURATION = 22

const DUMMY_PLAY_DURATION = 25

const FUNCTION_CALL_PRINT_INTERVAL = 1000000