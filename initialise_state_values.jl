using Dates

function create_interpolation_values()
    interpolation_calc_points = [1]
    interpolation_points = Vector{Int}()
    for section in NON_SCORING_FIELD_SECTIONS
        if mod(section, INTERPOLATION_SIZE) == 0
            push!(interpolation_calc_points, section)
        elseif section != TOUCHDOWN_SECTION - 1 && section != 1 && section != TOUCHDOWN_SECTION - 1
            push!(interpolation_points, section)
        end
    end
    if !in(TOUCHDOWN_SECTION - 1, interpolation_calc_points)
        push!(interpolation_calc_points, TOUCHDOWN_SECTION - 1)
    end

    interpolated_points_neighbours = Dict{Int,Tuple{Int,Int}}()

    for point in interpolation_points
        point_floor = floor(point / INTERPOLATION_SIZE)
        if point_floor == 0
            point_lower = 1
        else
            point_lower = point_floor * INTERPOLATION_SIZE
        end
        point_ceil = ceil(point / INTERPOLATION_SIZE)
        if point_ceil == ceil((TOUCHDOWN_SECTION - 1) / INTERPOLATION_SIZE)
            point_upper = TOUCHDOWN_SECTION - 1
        else
            point_upper = point_ceil * INTERPOLATION_SIZE
        end
        interpolated_points_neighbours[point] = (point_lower, point_upper)
    end

    return interpolation_calc_points, interpolation_points, interpolated_points_neighbours
end

function calculate_valid_score_diffs(current_score_diff, num_valid_scores)
    valid_score_diffs = Set([current_score_diff])
    for _ in 1:num_valid_scores
        iteration_possible_scores = Set()
        for score_diff in valid_score_diffs
            # Score TOUCHDOWN_SECTION
            push!(iteration_possible_scores, score_diff + TOUCHDOWN_SCORE)
            # Conceed td
            push!(iteration_possible_scores, score_diff - TOUCHDOWN_SCORE)
            # Score Field goal
            push!(iteration_possible_scores, score_diff + FIELD_GOAL_SCORE)
            # Conceed field goal
            push!(iteration_possible_scores, score_diff - FIELD_GOAL_SCORE)
            # Forced safety
            #push!(iteration_possible_scores, score_diff + SAFETY_SCORE)
            # Conceed safety
            #push!(iteration_possible_scores, score_diff - SAFETY_SCORE)
        end
        union!(valid_score_diffs, iteration_possible_scores)
    end
    # Check negative of each score is in array (can be set)
    for score_diff in valid_score_diffs
        if !in(-score_diff, valid_score_diffs)
            push!(valid_score_diffs, -score_diff)
        end
    end

    return valid_score_diffs
end

function initialise_state_values(
    initial_state::State
)
    # Get points to be calculate and points to be interpolated
    interpolation_calc_points, interpolated_points, interpolated_points_neighbours = create_interpolation_values()
    # Get max timeout 
    max_timeouts = max(
        initial_state.timeouts_remaining[1],
        initial_state.timeouts_remaining[2]
    )

    # Get all valid scores possible

    max_valid_scores = ceil(initial_state.seconds_remaining / MIN_TIME_TO_SCORE)
    valid_scores = []
    println("Valid scores")
    for num_scores in max_valid_scores
        valid_score_diffs = calculate_valid_score_diffs(
            initial_state.score_diff,
            num_scores
        )
        push!(valid_scores, valid_score_diffs)
        println("$(num_scores) scores: $(length(valid_score_diffs))")
    end

    interpolated_state_values = Dict{State,Tuple{Float64,String}}()
    for seconds in 1:initial_state.seconds_remaining-1
        sec_start_time = now()
        println("Initialising $seconds seconds")
        for score_diff in valid_scores[Int(ceil((initial_state.seconds_remaining - seconds) / MIN_TIME_TO_SCORE))]
            println("Score diff: $(score_diff)")
            for offensive_timeouts in 0:max_timeouts
                for defensive_timeouts in 0:max_timeouts
                    timeouts_remaining = (offensive_timeouts, defensive_timeouts)
                    println("Timeouts remaining: $(timeouts_remaining)")
                    for down in POSSIBLE_DOWNS
                        println("Down: $down")
                        #down_start_time = now()
                        for timeout_called in 0:1
                            # Can't have timeout called if no timeouts available for either team
                            if max_timeouts == 0 && timeout_called == 1
                                continue
                            end
                            timeout_called_val = Bool(timeout_called)
                            for clock_ticking in 0:1
                                clock_ticking_val = Bool(clock_ticking)
                                # Calculate value of points to be calculated
                                for ball_section in interpolation_calc_points
                                    for first_down_section in ball_section+1:min(TOUCHDOWN_SECTION, ball_section + MAX_DIST_TO_FIRST_DOWN)
                                        new_state = State(
                                            seconds_remaining,
                                            score_diff,
                                            timeouts_remaining,
                                            ball_section,
                                            down,
                                            first_down_section,
                                            timeout_called,
                                            clock_ticking,
                                            initial_state.is_first_half
                                        )
                                        new_state_value, new_state_action, _ = state_value_calc(new_state, interpolated_state_values)
                                        interpolated_state_values[new_state] = (new_state_value, new_state_action)
                                        #if timeouts_remaining == (0, 0)
                                        #    println("$(ball_section) | $(first_down_section)")
                                        #end
                                    end
                                end
                                #println(length(interpolated_state_values))
                                # Calculate value of points to be interpolated 
                                for ball_section in interpolated_points
                                    for first_down_section in ball_section+1:min(TOUCHDOWN_SECTION, ball_section + MAX_DIST_TO_FIRST_DOWN)
                                        neighbours = interpolated_points_neighbours[ball_section]
                                        ball_state = State(
                                            seconds,
                                            score_diff,
                                            timeouts_remaining,
                                            ball_section,
                                            down,
                                            first_down_section,
                                            timeout_called,
                                            clock_ticking,
                                            initial_state.is_first_half
                                        )
                                        lower_neigh = State(
                                            seconds,
                                            score_diff,
                                            timeouts_remaining,
                                            neighbours[1],
                                            down,
                                            min(first_down_section, neighbours[1] + MAX_DIST_TO_FIRST_DOWN),
                                            timeout_called,
                                            clock_ticking,
                                            initial_state.is_first_half
                                        )
                                        upper_neigh = State(
                                            seconds,
                                            score_diff,
                                            timeouts_remaining,
                                            neighbours[2],
                                            down,
                                            max(first_down_section, neighbours[2] + 1),
                                            timeout_called,
                                            clock_ticking,
                                            initial_state.is_first_half
                                        )
                                        lower_weight = (ball_section - neighbours[1]) / (neighbours[2] - neighbours[1])
                                        upper_weight = (neighbours[2] - ball_section) / (neighbours[2] - neighbours[1])
                                        if !haskey(interpolated_state_values, lower_neigh) || !haskey(interpolated_state_values, upper_neigh)
                                            println(ball_state)
                                            println(lower_neigh)
                                            println(upper_neigh)
                                            println("First down of lower_neigh: $(min(first_down_section, ball_section + MAX_DIST_TO_FIRST_DOWN))")
                                            println("First down: $(first_down_section)")
                                            println("Max first down from this section: $(ball_section + MAX_DIST_TO_FIRST_DOWN)")
                                            println("Ball seciton: $(ball_section)")
                                            println("Max dist consdtant: $(MAX_DIST_TO_FIRST_DOWN)")
                                        end
                                        new_state_expected_value = lower_weight * interpolated_state_values[lower_neigh][1] + upper_weight * interpolated_state_values[upper_neigh][1]
                                        new_state_action = interpolated_state_values[lower_neigh][2] # TODO: Find a way to do this better. Action is just same as lower neighbour
                                        interpolated_state_values[ball_state] = (new_state_expected_value, new_state_action)
                                    end
                                end
                            end
                        end
                        #down_end_time = now()
                        #println("Time for down: $(Millisecond(down_end_time - down_start_time).value / 1000) secodns")
                    end
                end
            end
        end
        sec_end_time = now()
        println("Time for calculating seconds: $(Millisecond(sec_end_time - sec_start_time).value / 1000) secodns")
        println("States calculated/interpolated: $(length(interpolated_state_values))")
    end
    return interpolated_state_values
end