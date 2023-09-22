# HONOURS-nflModel

This is my honours project. I am using dynamic programming to create a model that can determine the value of a position in American football and provide the most optimal decision in that position. 

## Data
The data is sourced from nfl-data-py. 
Because the play-by-play data spans 1999-2023, it is a very large file and has not been included in the repository. 
If you wish to install the file yourself run pip install nfl_data_py then run the file install_pbp_data.py

## Data processing
The data is processed using python. Values are stored in csv files. 

play_stats.csv: Holds the probabilities of transitioning between sections given the down, current section and whether a timeout has been called. 
punt_stats.csv: Holds the mean and standard deviation of punting (for all punts, no state information considered). This will be used to make a normal distribution in the model the create the probabilities. This will be improved in future. 
field_goal_stats.csv: Holds the probabilities of successfully kicking a field goal considering the field position. 

## Model
The model is created in julia. 
State space: Score, plays remaining, timeouts remaining, ball position, down, first down distance, whether the team is offense or defence, whether it is first or second half.
Action space: If on offense consider the following plays: Field goal attempt, punt, run a play, call a timeout and run the play