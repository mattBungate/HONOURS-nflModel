

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
            Function_calls=[state_value_calc_calls],
            Bytes_allocated=[bytes_allocated],
            Garbage_collection_time=[gc_time],
            Number_of_allocations=[num_allocations]
        )
        CSV.write("test_results/$(VERSION_NUM)", df_row, append=true)
    end
end

function test_kickoff(file_name::String)
    println("Starting kickoff testing")
    # Initialise
    df = DataFrame(
        seconds = Int[],
        timeouts_remaining = Int[],
        optimal_action = String[],
        action_value = Float64[],
        solve_time = Float64[],
        stored_states = Int[],
        function_calls = Int[]
    )

    no_search = [false, false, false, false]
    max_search_time = 40

    seconds_remaining = 1
    while true # seconds loop
        for timeouts_remaining in 0:3
            # Continue if no longer searching timeouts_remaining case
            if no_search[timeouts_remaining + 1]
                continue
            end
            global state_values = Dict{State, Tuple{Float64, String}}()
            global state_value_calc_calls = 0

            test_state = State(
                seconds_remaining,
                0,
                (timeouts_remaining, timeouts_remaining),
                TOUCHBACK_SECTION,
                FIRST_DOWN,
                FIRST_DOWN_TO_GO,
                false
            )

            try
                action_val, optimal_action, solve_time = run_with_timeout(
                    state_value_calc, 
                    max_search_time,
                    test_state
                )

                # Write solution to csv
                global state_values
                global state_value_calc_calls
                push!(
                    df,
                    (
                        seconds = seconds_remaining,
                        timeouts_remaining = timeouts_remaining,
                        optimal_action = optimal_action,
                        action_value = action_val,
                        solve_time = solve_time,
                        stored_states = length(state_values),
                        function_calls = state_value_calc_calls
                    )
                )
                CSV.write("tests/test_kickoff/$(file_name).csv", df)
                if solve_time > max_search_time
                    no_search[timeouts_remaining + 1] = true
                end
            catch e
                println("Task interrupted with error $e")
                no_search[timeouts_remaining + 1] = true
                println("$timeouts_remaining timeouts max seconds: $(seconds_remaining - 1)")
            end
        end
        # Check if all timed out
        break_out = true
        for case in no_search
            if case == false
                break_out = false
            end
        end
        seconds_remaining += 1
        # If we reach here we break out
        if break_out
            break
        end
    end
    CSV.write("tests/test_kickoff/$(file_name).csv", df)
end
