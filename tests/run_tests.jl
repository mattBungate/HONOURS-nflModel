

function run_tests()
    df = DataFrame(
        Test_id=Int[],
        Action_called=String[],
        Optimal_value=Float64[],
        Optimal_action=String[],
        Solve_Time=Float64[],
        States_stored=Int[],
        Function_calls=Int[],
        Bytes_allocated=Int[],
        Garbage_collectin_time=Float64[],
        Number_of_allocations=Int[]
    )
    CSV.write("tests/test_results/$(VERSION_NUM).csv", df)

    sorted_test_keys = sort(collect(keys(REAL_TESTS)), by=k -> REAL_TESTS[k][1].seconds_remaining)

    println("Testing all test states")
    for test_id in sorted_test_keys
        println("\nTest $test_id")
        # Get and print info on test
        test_state = REAL_TESTS[test_id][1]
        test_action = REAL_TESTS[test_id][2]
        println(REAL_TEST_DESCRIPTION[test_id])
        println(test_state)
        # Reinitialise state_values
        state_values = Dict{State,Tuple{Float64,String}}()
        state_value_calc_calls = 0
        # Calculate value
        @time state_value, time_elapsed, bytes_allocated, gc_time, num_allocations = state_value_calc(
            test_state
        )
        # Print results
        println("States stored: $(length(state_values))")
        println("Number of state value function calls: $(state_value_calc_calls)")
        println("Action values:")
        for (key, value) in state_value[3]
            println(key, " | ", value)
        end
        println()

        # Write to CSV File
        df_row = DataFrame(
            Test_id=[test_id],
            Action_called=[test_action],
            Optimal_value=[state_value[1]],
            Optimal_decision=[state_value[2]],
            Solve_time=[time_elapsed],
            States_stored=[length(state_values)],
            Function_calls=[state_value_calc_calls]
            Bytes_allocated = [bytes_allocated],
            Garbage_collection_time=[gc_time],
            Number_of_allocations=[num_allocations]
        )
        CSV.write("test_results/$(VERSION_NUM)", df_row, append=true)
    end
end