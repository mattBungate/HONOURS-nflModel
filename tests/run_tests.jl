

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

function test_kickoff(
    file_name::String, 
    start_seconds_remaining::Int=1,
    max_search_time::Int=300
)
    println("Starting kickoff testing")
    # Initialise
    df = DataFrame(
        seconds = Int[],
        timeouts_remaining = Int[],
        optimal_action = String[],
        action_value = Float64[],
        solve_time = Float64[],
        total_stored_states = Int[],
        total_function_calls = Int[],
        play_stored_states = Int[],
        play_function_calls = Int[],
        conversion_stored_states = Int[],
        conversion_function_calls = Int[],
        kickoff_stored_states = Int[],
        kickoff_function_calls = Int[]
    )

    no_search = [false, false, false, false]

    seconds_remaining = start_seconds_remaining
    while true # seconds loop
        for timeouts_remaining in 0:3
            # Continue if no longer searching timeouts_remaining case
            if no_search[timeouts_remaining + 1]
                continue
            end
            # Reinitialise stats - TODO: turn this into function for simplicity/readability
            global play_state_values = Dict{PlayState, Tuple{Float64,String}}()
            global play_decision_calc_calls = 0
            global conversion_state_values = Dict{ConversionState, Tuple{Float64, String}}()
            global conversion_decision_calc_calls = 0
            global kickoff_state_values = Dict{KickoffState, Tuple{Float64,String}}()
            global kickoff_decision_calc_calls = 0

            test_state = KickoffState(
                seconds_remaining,
                (timeouts_remaining, timeouts_remaining),
            )

            print("Solving $(seconds_remaining) second with $(timeouts_remaining) timeouts")
            start_time = time()
            action_val, optimal_action = state_value_calc(test_state, true)
            end_time = time()
            solve_time = end_time - start_time

            # Write solution to csv
            global play_state_values
            global play_decision_calc_calls
            global conversion_state_values
            global conversion_decision_calc_calls
            global kickoff_state_values
            global kickoff_decision_calc_calls
            total_states_stored = length(play_state_values) + length(conversion_state_values) + length(kickoff_state_values)
            total_function_calls = play_decision_calc_calls + conversion_decision_calc_calls + kickoff_decision_calc_calls
            push!(
                df,
                (
                    seconds = seconds_remaining,
                    timeouts_remaining = timeouts_remaining,
                    optimal_action = optimal_action,
                    action_value = action_val,
                    solve_time = solve_time,
                    total_stored_states = total_states_stored,
                    total_function_calls = total_function_calls,
                    play_stored_states = length(play_state_values),
                    play_function_calls = play_decision_calc_calls,
                    conversion_stored_states = length(conversion_state_values),
                    conversion_function_calls = conversion_decision_calc_calls,
                    kickoff_stored_states = length(kickoff_state_values),
                    kickoff_function_calls = kickoff_decision_calc_calls
                )
            )
            print(" - Solved ($(round(solve_time, digits=2))s)\n")
            CSV.write("tests/test_kickoff/$(file_name).csv", df)
            if solve_time > max_search_time
                no_search[timeouts_remaining + 1] = true
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
