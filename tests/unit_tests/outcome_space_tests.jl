

"""
Unit tests for field goal outcome space calculations
"""
function test_field_goal_outcome_space_generation()
    """ 
    Assumed constant values 

    FIELD_GOAL_MERCY_SECTION = 20
    MIN_FIELD_GOAL_DURATION = 1
    MAX_FIELD_GOAL_DURATION = 9
    PROB_TOL = 10e-4
    TOUCHBACK_SECTION = 20
    FIRST_DOWN = 1
    FIRST_DOWN_TO_GO = 10
    FIELD_GOAL_SCORE = 3
    FIELD_GOAL_CUTOFF = 50 (will work for any value greater than 10)
    """
    """ TEST VARIABLES """
    # Cutoff - Outside of field goal range
    cutoff_state = State(50, 0, (1,2), 10, 1, 10, true)
    cutoff_expected = ()
    cutoff_failed = false
    # Mercy - Inside mercy zone. If missed, ball placed on 20 instead of kick position
    mercy_state = State(50, 0, (1,2), 90, 1, 10, true)
    mercy_expected_states = (
        State(49, -3, (2,1), 25, 1, 10, false),
        State(48, -3, (2,1), 25, 1, 10, false),
        State(47, -3, (2,1), 25, 1, 10, false),
        State(46, -3, (2,1), 25, 1, 10, false),
        State(45, -3, (2,1), 25, 1, 10, false),
        State(44, -3, (2,1), 25, 1, 10, false),
        # State(43, -3, (2,1), 25, 1, 10, false), doesn't reach prob threshold
        # State(42, -3, (2,1), 25, 1, 10, false), doesn't reach prob threshold
        # State(41, -3, (2,1), 25, 1, 10, false), doesn't reach prob threshold
        # State(49, 0, (2,1), 20, 1, 10, false), doesn't reach prob threshold
        State(48, 0, (2,1), 20, 1, 10, false),
        State(47, 0, (2,1), 20, 1, 10, false),
        State(46, 0, (2,1), 20, 1, 10, false),
        State(45, 0, (2,1), 20, 1, 10, false),
        State(44, 0, (2,1), 20, 1, 10, false),
        # State(43, 0, (2,1), 20, 1, 10, false), doesn't reach prob threshold
        # State(42, 0, (2,1), 20, 1, 10, false), doesn't reach prob threshold
        # State(41, 0, (2,1), 20, 1, 10, false), doesn't reach prob threshold
    )
    mercy_failed = false
    # Normal - inside field goal range and outside of mercy zone
    normal_state = State(50, 0, (1,2), 70, 1, 10, true)
    normal_expected_states = (
        State(49, -3, (2,1), 25, 1, 10, false),
        State(48, -3, (2,1), 25, 1, 10, false),
        State(47, -3, (2,1), 25, 1, 10, false),
        State(46, -3, (2,1), 25, 1, 10, false),
        State(45, -3, (2,1), 25, 1, 10, false),
        State(44, -3, (2,1), 25, 1, 10, false),
        State(43, -3, (2,1), 25, 1, 10, false),
        State(42, -3, (2,1), 25, 1, 10, false),
        # State(41, -3, (2,1), 25, 1, 10, false), doesn't meet prob threshold
        State(49, 0, (2,1), 30, 1, 10, false),
        State(48, 0, (2,1), 30, 1, 10, false),
        State(47, 0, (2,1), 30, 1, 10, false),
        State(46, 0, (2,1), 30, 1, 10, false),
        State(45, 0, (2,1), 30, 1, 10, false),
        State(44, 0, (2,1), 30, 1, 10, false),
        State(43, 0, (2,1), 30, 1, 10, false),
        State(42, 0, (2,1), 30, 1, 10, false),
        # State(41, 0, (2,1), 30, 1, 10, false), doesn't meet prob threshold
    )
    normal_failed = false
    # EOGP - End Of Game Possible
    EOGP_state = State(3, 0, (2, 1), 70, 1, 10, false)
    EOGP_expected_states = (
        State(2, -3, (1,2), 25, 1, 10, false),
        State(1, -3, (1,2), 25, 1, 10, false),
        State(0, -3, (1,2), 25, 1, 10, false),
        State(2, 0, (1,2), 30, 1, 10, false),
        State(1, 0, (1,2), 30, 1, 10, false),
        State(0, 0, (1,2), 30, 1, 10, false),
    )
    EOGP_failed = false
    # Test counters
    passed_tests = 0
    total_tests = 0


    """ Tests """ 
    println("\n--- FIELD GOAL OUTCOME SPACE TESTING ---")

    # Cutoff test
    cutoff_output = field_goal_outcome_space(cutoff_state)
    if length(cutoff_output) > 0
        print("|")
        cutoff_failed = true
    else
        print("-")
        passed_tests += 1
    end
    total_tests += 1

    # Mercy test
    mercy_output = field_goal_outcome_space(mercy_state)
    for ((calculated_state, _, _), expected_state) in zip(mercy_output, mercy_expected_states)
        if calculated_state != expected_state
            println("Calculated state: $(calculated_state)")
            println("Expected state: $(expected_state)")
            mercy_failed = true
            print("|")
            break
        end
    end
    if !mercy_failed
        print("-")
        passed_tests += 1
    end
    total_tests += 1

    # Normal test
    normal_output = field_goal_outcome_space(normal_state)
    for ((calculated_state, _, _), expected_state) in zip(normal_output, normal_expected_states)
        if calculated_state != expected_state
            println("Calculated state: $(calculated_state)")
            println("Expected state: $(expected_state)")
            normal_failed = true
            print("|")
            break
        end
    end
    if !normal_failed
        print("-")
        passed_tests += 1
    end
    total_tests += 1

    # EOGP test
    EOGP_output = field_goal_outcome_space(EOGP_state)
    for ((calculated_state, _, _), expected_state) in zip(EOGP_output, EOGP_expected_states)
        if calculated_state != expected_state
            println("Calculated state: $(calculated_state)")
            println("Expected state: $(expected_state)")
            EOGP_failed = true
            print("|")
            break
        end
    end
    if !EOGP_failed
        print("-")
        passed_tests += 1
    end
    total_tests += 1

    """ FINAL OUTPUT """
    println("\nPassed tests: ($(passed_tests) / $(total_tests))")
    if passed_tests != total_tests
        println("Failed tests:")
        if cutoff_failed
            println("Cutoff - states generated")
        end
        if mercy_failed
            if length(mercy_output) == length(mercy_expected_states)
                println("Mercy  - incorrect value of states")
                """
                println("\nOutput:")
                println(mercy_output)
                println("\nExpected")
                println(mercy_expected_states)
                """
            else
                println("Mercy  - incorrect number of states ($(length(mercy_output)) != $(length(mercy_expected_states)))")
            end
        end
        if normal_failed
            if length(normal_output) == length(normal_expected_states)
                println("Normal - incorrect value of states")
            else
                println("Normal - incorrect number of states ($(length(normal_output)) != $(length(normal_expected_states)))")
            end
        end
        if EOGP_failed
            if length(EOGP_output) == length(EOGP_expected_states)
                println("End Of Game Possible - incorrect value of states")
            else
                println("End Of Game Possible - incorrect number of states ($(length(EOGP_output)) != $(length(EOGP_expected_states)))")
            end
        end
    end
end
