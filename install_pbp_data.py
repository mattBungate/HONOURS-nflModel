import nfl_data_py as nfl
import pandas as pd


pbp_data = nfl.import_pbp_data(years=list(range(1999,2023)))

pbp_data.to_csv("pbp_data.csv")