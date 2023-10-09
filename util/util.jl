"""
Random functions

Mostly small functions that I've renamed for readability sake in the model
"""
function flip_field(ball_section)
    return TOUCHDOWN_SECTION - ball_section
end