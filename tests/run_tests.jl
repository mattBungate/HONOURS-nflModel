

function run_tests(
    is_timeout::Bool,
    max_runtime::Int=60,
    max_iter::Int=10000
)

    df = DataFrame(
        Test_id=Int[],
        Action_called=String[],
        Optimal_value=Float64[],
        Optimal_action=String[],
        Solve_Time=Float64[],
        Iterations=Int[]
    )
    CSV.write("tests/test_results/$(VERSION_NUM).csv", df)

    sorted_test_keys = sort(collect(keys(REAL_TESTS)), by=k -> REAL_TESTS[k][1].seconds_remaining)

    println("Testing all test states")
    for test_id in sorted_test_keys
        println("\nTest $test_id")
        # Get and print info on test
        test_state = REAL_TESTS[test_id][1]
        test_first_half = REAL_TESTS[test_id][2]
        test_action = REAL_TESTS[test_id][3]
        println(REAL_TEST_DESCRIPTION[test_id])
        println(test_state)

        # Calculate value
        if is_timeout
            optimal_action, action_score, time_elapsed, iterations = run_with_timeout(
                solve_MCTS, 
                max_runtime, 
                test_state, 
                test_first_half)
        else
            optimal_action, action_score, time_elapsed, iterations = solve_MCTS(
                test_state,
                test_first_half,
                max_iter,
            )
        end
        # Print results
        println("Optimal action: $(optimal_action)")
        println("Estimated optimal action value: $(action_score)")
        println("Time elapsed: $(time_elapsed)")
        println("Iterations: $(iterations)")

        # Write to CSV File
        df_row = DataFrame(
            Test_id=[test_id],
            Action_called=[test_action],
            Optimal_value=[optimal_action],
            Optimal_action=[action_score],
            Solve_time=[time_elapsed],
            Iterations=[iterations]
        )
        CSV.write("tests/test_results/$(VERSION_NUM).csv", df_row, append=true)
    end
end
