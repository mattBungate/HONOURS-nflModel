

function run_tests()
    df = DataFrame(
        Test_id=Int[],
        Timeouts_remaining=[],
        Action_called=String[],
        Optimal_value=Float64[],
        Optimal_action=String[],
        Solve_Time=Float64[],
        Total_states_stored=Int[],
        Total_function_calls=Int[],
        Play_states_stored=Int[],
        Play_function_calls=Int[],
        Conversion_states_stored=Int[],
        Conversion_function_calls=Int[],
        Kickoff_states_stored=Int[],
        Kickoff_function_calls=Int[]
    )
    CSV.write("tests/test_results/$(VERSION_NUM).csv", df)

    sorted_test_keys = sort(collect(keys(REAL_TESTS)), by=k -> REAL_TESTS[k][1].seconds_remaining)

    println("Testing all test states")
    for test_id in sorted_test_keys
        println("\n---- Test $test_id ----")
        # Get and print info on test
        test_state = REAL_TESTS[test_id][1]
        test_action = REAL_TESTS[test_id][2]
        println(REAL_TEST_DESCRIPTION[test_id])
        for timeouts_remaining in 0:max(test_state.timeouts_remaining[1], test_state.timeouts_remaining[2])
            # Reinitialise stats - TODO: Tun this into function for simplicity/readability
            global play_state_values = Dict{PlayState,Tuple{Float64,String}}()
            global play_decision_calc_calls = 0
            global conversion_state_values = Dict{ConversionState,Tuple{Float64,String}}()
            global conversion_decision_calc_calls = 0
            global kickoff_state_values = Dict{KickoffState,Tuple{Float64,String}}()
            global kickoff_decision_calc_calls = 0
            
            # New state depending on value
            timeout_test_state = PlayState(
                test_state.seconds_remaining,
                test_state.score_diff,
                (min(test_state.timeouts_remaining[1], timeouts_remaining), min(test_state.timeouts_remaining[2], timeouts_remaining)),
                test_state.ball_section,
                test_state.down,
                test_state.first_down_dist,
                test_state.clock_ticking
            )
            println(timeout_test_state)
            # Calculate value
            start_time = time()
            state_value = state_value_calc(
                timeout_test_state,
                true
            )
            end_time = time()
            time_elapsed = end_time - start_time
            # Print results - TODO: Turn this into function for simplicity
            global play_state_values
            global play_decision_calc_calls
            global conversion_state_values
            global conversion_decision_calc_calls
            global kickoff_state_values
            global kickoff_decision_calc_calls
            states_explored = length(play_state_values) + length(conversion_state_values) + length(kickoff_state_values)
            function_calls = play_decision_calc_calls + conversion_decision_calc_calls + kickoff_decision_calc_calls
            println("Plays: $(length(play_state_values)) states | $play_decision_calc_calls calls")
            println("Converions: $(length(conversion_state_values)) states | $conversion_decision_calc_calls calls")
            println("Kickoffs: $(length(kickoff_state_values)) states | $kickoff_decision_calc_calls calls")
            println("Total: $(states_explored) states | $function_calls calls")
            println("Solve time: $(time_elapsed)")
            println()

            # Write to CSV File
            df_row = DataFrame(
                Test_id=[test_id],
                Timeouts_remaining=[timeouts_remaining],
                Action_called=[test_action],
                Optimal_value=[state_value[1]],
                Optimal_decision=[state_value[2]],
                Solve_time=[time_elapsed],
                Total_states_stored=[states_explored],
                Total_function_calls=[function_calls],
                Play_states_stored=[length(play_state_values)],
                Play_function_calls=[play_decision_calc_calls],
                Conversion_states_stored=[length(conversion_state_values)],
                Conversion_function_calls=[conversion_decision_calc_calls],
                Kickoff_states_stored=[length(kickoff_state_values)],
                Kickoff_function_calls=[kickoff_decision_calc_calls]
            )
            CSV.write("test_results/$(VERSION_NUM).csv", df_row, append=true)
        end
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
            # Reinitialise stats - TODO: Tun this into function for simplicity/readability
            global play_state_values = Dict{PlayState,Tuple{Float64,String}}()
            global play_decision_calc_calls = 0
            global conversion_state_values = Dict{ConversionState,Tuple{Float64,String}}()
            global conversion_decision_calc_calls = 0
            global kickoff_state_values = Dict{KickoffState,Tuple{Float64,String}}()
            global kickoff_decision_calc_calls = 0

            test_state = KickoffState(
                seconds_remaining,
                0, 
                (timeouts_remaining, timeouts_remaining)
            )

            print("Solving $(seconds_remaining) second with $(timeouts_remaining) timeouts")
            start_time = time()
            action_val, optimal_action = state_value_calc(
                test_state,
                true
            )
            end_time = time()
            solve_time = round(end_time - start_time, digits=3)

            # Write solution to csv
            global play_state_values
            global play_decision_calc_calls
            global conversion_state_values
            global conversion_decision_calc_calls
            global kickoff_state_values
            global kickoff_decision_calc_calls
            total_states_stored = length(play_state_values) + length(conversion_state_values) + length(kickoff_state_values)
            total_function_calc_calls = play_decision_calc_calls + conversion_decision_calc_calls + kickoff_decision_calc_calls
            push!(
                df,
                (
                    seconds = seconds_remaining,
                    timeouts_remaining = timeouts_remaining,
                    optimal_action = optimal_action,
                    action_value = action_val,
                    solve_time = solve_time,
                    total_stored_states = total_states_stored,
                    total_function_calls = total_function_calc_calls,
                    play_stored_states = length(play_state_values),
                    play_function_calls = play_decision_calc_calls,
                    conversion_stored_states = length(conversion_state_values),
                    conversion_function_calls = conversion_decision_calc_calls,
                    kickoff_stored_states = length(kickoff_state_values),
                    kickoff_function_calls = kickoff_decision_calc_calls
                )
            )
            print(" - Solved ($(solve_time)s)\n")
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
    println(df)
    CSV.write("tests/test_kickoff/$(file_name).csv", df)
end