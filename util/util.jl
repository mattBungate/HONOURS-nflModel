"""
Random functions

Mostly small functions that I've renamed for readability sake in the model
"""
function flip_field(ball_section)
    return TOUCHDOWN_SECTION - ball_section
end

function run_with_timeout(
    func::Function, 
    timeout_seconds::Int,
    state::State,
    is_first_half::Bool
)::Tuple{String, Float64, Float64, Int} # Same as MCTS_solve output
    result = ("START RESULT", -1.0, -1.0, -1)
    @sync begin
        task = @async begin
            try
                result = func(state, is_first_half)
            catch e
                println("Task interrupted or an error occurred: $e")
                if !isa(e, InterruptException)
                    result = ("Timeout with no result", -1.0, -1.0, -1)
                end
            finally
                println("We are now exiting the @async block")
                println("Result value: $(result)")
                yield()
            end
        end
        sleep(timeout_seconds)
        println("Timeout reached.")
        schedule(task, InterruptException(), error=true)
        sleep(20) # This is an attempt to let the MCTS finish out what it needs to
    end
    println("Exiting run_with_timeout")
    return result
end