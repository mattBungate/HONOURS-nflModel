"""
All the constants that are used throughout this codebase
"""

const SECTION_WIDTH = 1                                     # Width of the sections

const FIELD_SECTIONS = [i for i in 0:100]                   # All field sections
const NON_SCORING_FIELD_SECTIONS = [i for i in 1:99]        # Field sections that aren't end zones
const TOUCHBACK_SECTION = 25                                # Touchback is 25yrd line (section 3)
const TOUCHDOWN_SECTION = 100                               # Scoring touchdown section
const TOUCHDOWN_CONCEEDED_SECTION = 0                       # Conceeding touchdown section
const FIELD_GOAL_MERCY_SECTION = 20                         # If a field goal inside this the ball is placed on the 25

const POSSIBLE_DOWNS = [1,2,3,4]                            # All downs possible

const TOUCHDOWN_SCORE = 7                                   # Score of a touchdown
const FIELD_GOAL_SCORE = 3                                  # Score of a field goal

const FIRST_DOWN_TO_GO = 10                                 # Dist to first down if first down 
const FIRST_DOWN = 1                                        # For clarity

const PROB_TOL = 10e-16                                     # If prob is under its considered insignificant
const GROUP_PROB_TOL = 10e-8                                # If group prob is under its considered insignificant group
