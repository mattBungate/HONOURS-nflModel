# Optimal Play Calling and Time Management in the NFL
## Version 2: Initial model

This is my honours project. I am using dynamic programming to create a model that can determine the value of a position in American football and provide the most optimal decision in that position. 

## Data
The data is sourced from [nfl-data-py](https://pypi.org/project/nfl-data-py/). 
Because the play-by-play data spans 1999-2023, it is a very large file and has not been included in the repository. 
To install the play by play csv file, run `pip install nfl_data_py` then run the following code:

```python
import nfl_data_py as nfl
import pandas as pd

pbp_data = nfl.import_pbp_data(years=list(range(1999,2023)))

pbp_data.to_csv("pbp_data.csv")
```

## Data processing
The data is processed using python. Values are stored in csv files. 

play_stats.csv: Holds the probabilities of transitioning between sections given the down, current section and whether a timeout has been called. 
punt_stats.csv: Holds the mean and standard deviation of punting (for all punts, no state information considered). This will be used to make a normal distribution in the model the create the probabilities. This will be improved in future. 
field_goal_stats.csv: Holds the probabilities of successfully kicking a field goal considering the field position. 

## Model
The model is created in julia. More details on formulation can be found in overleaf file but the model will have the following when fully implemented: 

**State space**: Score, plays remaining, timeouts remaining, ball position, down, first down distance, whether the team is offense or defence, whether it is first or second half.
**Action space**: If on offense consider the following plays: Field goal attempt, punt, run a play, call a timeout and run the play

---

### Version Major Changes | V.1.5.1 -> V.2.0.0
The focus of this version is implementing a proper sense of time to the model. The main difference will be changing State.plays_remaining to State.seconds_remaining. This also allows a game clock to be implemented. With these two changes the model can begin optimising time management. With this in mind, the action space will also be expanded to include time sensitive plays

#### Implementation:
##### Plays to Seconds
- [ ] Update data_processing.py to include probabilities to include length of play
- [ ] Change State.plays_remaining to State.seconds_remaining
- [ ] Update all action functions to account for State change
##### Game Clock
- [ ] Add binary indicator to State to represent whether the clock is ticking or not
- [ ] Add data about the typical time between plays
- [ ] Change action functions to account for new binary indicator & clock
##### Expanding Action Space
- [ ] Spike
- [ ] Kneel
- [ ] Kneel out game (new terminal case)
- [ ] Use minimal time for play
- [ ] Run down clock with plays