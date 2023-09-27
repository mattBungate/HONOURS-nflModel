import pandas as pd
import numpy as np
import time
import matplotlib.pyplot as plt
import math

from scipy.stats import norm    # Calculate and use norm dist
from scipy.optimize import curve_fit


def calculate_stats():
    print("In calculate_stats()")
    start_time = time.time()
    pbp_df = pd.read_csv('all_pbp.csv')
    print("CSV file read")
    df_size = len(pbp_df.index)

    possible_downs = [1,2,3,4]
    field_sections = [i for i in range(12)]
    timeout_used_options = [0,1]

    yards_gained = {}
    for down in possible_downs:
        for section in field_sections:
            for timeout in timeout_used_options:
                yards_gained[down, section, timeout] = []
    
    punt_yards = []
    punt_return_yards = []
    punt_nan_counter = 0
    punt_return_nan_counter = 0

    field_goal_attempts = {}
    for section in field_sections:
        field_goal_attempts[section] = []

    # Iterate through each row
    for index, row in pbp_df.iterrows():
        if index % 10000 == 0:
            print(f'{index} | {round(100*index/df_size,4)}')
        # Was this a valid play (only look at run or pass plays for now)
        if row["play_type"] == 'run' or row["play_type"] == 'pass':
            # Get the down, current position, Timeout used
            down = row["down"]
            starting_position = row['yardline_100']
            starting_section = math.ceil(starting_position/10)
            if row['timeout'] == 1:
                timeout_used = 1
            else:
                timeout_used = 0
            
            # Skip any plays that have nan values
            if math.isnan(down) or math.isnan(starting_position) or math.isnan(row['yards_gained']): 
                continue
            # Store the yards gained.
            try:    
                yards_gained[down, starting_section, timeout_used].append(row['yards_gained'])
            except:
                print(row)
                xxxxx
        
        # Punt data
        if row["play_type"] == "punt":
            # Add data for punt
            if math.isnan(row['kick_distance']):
                #print("Punt nan found")
                punt_nan_counter += 1
            else:
                punt_yards.append(row['kick_distance'])
            
            # Add data for return
            if math.isnan(row['return_yards']):
                print("Punt return nan found")
                punt_return_nan_counter += 1
            else:
                punt_return_yards.append(row['return_yards'])
        # Field goal data
        if row["play_type"] == "field_goal":
            # Get the field section
            position = row['yardline_100']
            section = math.ceil(position/10)
            # add result to dictionary
            if row["field_goal_result"] == "made":
                field_goal_attempts[section].append(1)
            else:
                field_goal_attempts[section].append(0)

    # Create transition probabilities
    stats_df = pd.DataFrame(columns=['Down', 'Field Section', 'Timeout Used', 'T-0', 'T-1', 'T-2', 'T-3', 'T-4', 'T-5', 'T-6', 'T-7', 'T-8', 'T-9', 'T-10', 'T-11'])

    num_calculated = 0

    for down in possible_downs:
        for section in field_sections:
            if section == 0 or section == 11:
                continue
            for timeout in timeout_used_options:
                mean = np.mean(yards_gained[(down, section, timeout)])
                std = np.std(yards_gained[down, section, timeout])

                normal_dist = norm(loc=mean, scale=std)

                probs = []
                for end_section in field_sections:
                    # Handle conceed TD
                    if end_section == 0:
                        probs.append(normal_dist.cdf(5 - 10*section))
                    # Handle score TD
                    elif end_section == 12:
                        probs.append(1 - normal_dist.cdf(105 - 10*section))
                    # Hanlde no score
                    else:
                        probs.append(normal_dist.cdf((end_section - section)*10 + 5) - normal_dist.cdf((end_section - section)*10 - 5))


                df_entry = [down, section, timeout] + probs
                stats_df.loc[num_calculated] = df_entry

                num_calculated += 1
    
    stats_df.to_csv('stats.csv')

    punt_return_df = pd.DataFrame(columns=["Mean", "Average"])
    punt_return_df.loc[1] = [np.mean(punt_yards) - np.mean(punt_return_yards), np.sqrt(np.std(punt_yards)**2 + np.std(punt_return_yards)**2)]
    punt_return_df.to_csv('punt_stats.csv')

    # Create field goal data
    field_goal_df = pd.DataFrame(columns=['T-1', 'T-2', 'T-3', 'T-4', 'T-5', 'T-6', 'T-7', 'T-8', 'T-9', 'T-10'])
    df_entry = []
    for section in field_sections:
        if section == 0 or section == 11:
            continue 
        fg_attempts = len(field_goal_attempts[section])
        fg_made = 0
        if fg_attempts == 0:
            df_entry.append(0)
        else:
            fg_made = np.sum(field_goal_attempts[section])
            df_entry.append(fg_made/fg_attempts)
    df_entry_reversed = df_entry.reverse()
    field_goal_df.loc[1] = df_entry_reversed

    field_goal_df.to_csv('field_goal_stats.csv')

    end_time = time.time()

    print(f'Time to run calculate_stats(): {end_time - start_time}')

calculate_stats()