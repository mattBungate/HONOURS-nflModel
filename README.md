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

**play_stats.csv**: Holds the probabilities of transitioning between sections given the down, current section and whether a timeout has been called. 
**punt_probs.csv**: Holds the probabilities of transitioning between sections given the position on the field. This gives probability of the final position of the ball, after the punt AND return. 
**field_goal_stats.csv**: Holds the probabilities of successfully kicking a field goal considering the field position. 

---

## Version 1 - Initial Model
Version 1 is about creating the simplest model to have a base to build upon for future models.

### State Space
The factors that are taken into consideration are:
- Plays remaining
- Score differential
- Timeouts remaining
- Ball section
- Down
- First down section
- Timeout called before this decision/play

### Action Space
The actions that can be taken, along with the constraints on when they can be taken are as follows:
- Kneel (anytime)
- Field Goal (when the ball is starting in the attacking half)
- Punt (anytime)
- Play and no timeout at end of play (anytime)
- Play and timeout at end of play (when there are timeouts remaining)

### Outcome Space
Follows the rules of an NFL game. Every play will result in transitioning to a state where plays remaining has decreasing by one. This is used to determine if the state is in a terminal case. 

Additionally, we have that the model is in the perspective of the team with the ball. This means that when a change in possession of the ball occurs some actions must be taken:
- Score differential is flipped. 
- The sections (ball & first down) must be flipped to be perspective of new team
- The final play that results in the change in posesion should subtract instead of add the value of the new value
- Timeouts remaining needs to be in the perspective of new team in possession

## Version 2 - Time implementation
The main purpose of version 2 is to implement time in a more effective manner. The plays remaining framework from version 1 is very crude and does not allow for insightful or interesting results from optimisation. With a proper implementation of time the model will become signficantly more intricate and complex and will provide more insightful results from optimisation.

### State Space
The factors that are taken into consideration for a state are:
- Seconds remaining
- Score differential
- Timeouts remaining
- Ball section
- Down
- Firsst down section
- Timeout called before this decision/play

### Outcome Space
Follows the rules of an NFL game. Every play will result in transitioning to a state where the seconds remaining have decreased. The seconds remaining is used to determine if the state is in a terminal case. 

Instead of taking the expected value of each state resulted from every possible yards gained value, we need to consider the expected value of each state resulting from the yards gained AND time duration of play value. 

## Version 3 - DFS
Depth First Search (DFS) is the approach that was implemented in the above. Version 2 found that the state space was too large to completely search through all states and the runtime was becoming unreasonable, especially as the number of seconds remaining increased. Version 3 (DFS branch) looks at methods for handling this. This includes:
- Limited depth then an estimation on the evaluation of the state (L-DFS)
- Iteratively decrease interpolation step sizes to approach the optimal answer
- Iteratively increase the refinement of the state space to converge to the optimal answer. 