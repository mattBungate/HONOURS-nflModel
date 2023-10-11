import pandas as pd
import numpy as np
import time
import matplotlib.pyplot as plt
import math

from scipy.stats import norm    # Calculate and use norm dist
from scipy.optimize import curve_fit


def clock_stopped(desc, incomplete_pass):
    if not math.isnan(incomplete_pass) and incomplete_pass == 1:
        return True

    desc_split = desc.split(" ")
    if "ob" in desc_split:
        return True
    else:
        return False


def calculate_stats():
    start_time = time.time()
    print("In calculate_stats()")
    #pbp_df = pd.read_csv('all_pbp.csv')
    pbp_df = pd.read_csv("random/pbp_2022.csv")
    print("CSV file read")
    df_size = len(pbp_df.index)

    possible_downs = [1, 2, 3, 4]
    field_sections = [i for i in range(12)]
    timeout_used_options = [0, 1]

    yards_gained = {}
    for down in possible_downs:
        for section in field_sections:
            for timeout in timeout_used_options:
                yards_gained[down, section, timeout] = []

    punt_yards = []
    punt_return_yards = []
    punt_nan_counter = 0
    punt_return_nan_counter = 0
    punt_times = {}

    field_goal_attempts = {}
    field_goal_times = {}
    for section in field_sections:
        field_goal_attempts[section] = []
        field_goal_times[section] = []

    time_values_clock_stopped = {}
    time_values_clock_not_stopped = {}

    print("Initialised everything")

    # Iterate through each row
    for index, row in pbp_df.iterrows():
        if index % 1000 == 0:
            print(f'{index} | {round(100*index/df_size,4)}')

        if index == pbp_df.index[-1]:
            break
        play_type = row['play_type']
        current_remaining = row['half_seconds_remaining']
        next_remaining = pbp_df.iloc[index + 1]['half_seconds_remaining']
        dist_gained = row['yards_gained']
        if math.isnan(current_remaining) or math.isnan(next_remaining) or math.isnan(dist_gained) or current_remaining <= next_remaining:
            continue
        else:
            play_time = current_remaining - next_remaining
            # Play executed
            if play_type == "pass" or play_type == "run":
                if clock_stopped(row['desc'], row['incomplete_pass']):
                    if dist_gained not in time_values_clock_stopped.keys():
                        time_values_clock_stopped[dist_gained] = []
                    time_values_clock_stopped[dist_gained].append(play_time)
                else:
                    if dist_gained not in time_values_clock_not_stopped.keys():
                        time_values_clock_not_stopped[dist_gained] = []
                    time_values_clock_not_stopped[dist_gained].append(
                        play_time)
            # Punt
            elif play_type == "punt":
                # Add data for punt
                if math.isnan(row['kick_distance']):
                    continue
                else:
                    punt_dist = row['kick_distance']

                # Add data for return
                if math.isnan(row['return_yards']):
                    continue
                else:
                    return_dist = row['return_yards']

                punt_net_dist = punt_dist - return_dist
                if punt_net_dist not in punt_times.keys():
                    punt_times[punt_net_dist] = []
                punt_times[punt_net_dist].append(play_time)

            # Field goal
            elif play_type == "field_goal":
                field_goal_section = int(math.ceil(row['yardline_100'] / 10))
                field_goal_section = 11 - field_goal_section
                field_goal_times[field_goal_section].append(play_time)

    for key in sorted(time_values_clock_stopped):
        print(f"{key} | {len(time_values_clock_stopped[key])}")
    print()
    for key in sorted(time_values_clock_not_stopped):
        print(f"{key} | {len(time_values_clock_not_stopped)}")

    min_seconds = math.inf
    max_seconds = 0
    for key in sorted(time_values_clock_stopped.keys()):
        if min_seconds > min(time_values_clock_stopped[key]):
            min_seconds = min(time_values_clock_stopped[key])
        elif max_seconds < max(time_values_clock_stopped[key]):
            max_seconds = max(time_values_clock_stopped[key])

    for key in sorted(time_values_clock_not_stopped.keys()):
        if min_seconds > min(time_values_clock_not_stopped[key]):
            min_seconds = min(time_values_clock_not_stopped[key])
        elif max_seconds < max(time_values_clock_not_stopped[key]):
            max_seconds = max(time_values_clock_not_stopped[key])

    min_seconds = int(min_seconds)
    max_seconds = int(max_seconds)

    print(f"Max seconds: {max_seconds} | Min seconds: {min_seconds}")
    columns = ["Yards Gained", "Clock Stopped"]
    for i in range(min_seconds, max_seconds + 1):
        columns.append(f"{i} seconds")

    all_keys = list(set(list(time_values_clock_not_stopped.keys()) +
                        list(time_values_clock_stopped.keys())))

    print(all_keys)

    time_df = pd.DataFrame(columns=columns)
    num_calculated = 0
    for key in all_keys:
        print(all_keys)
        # Clock stopped stats
        clock_stopped_stats = [key, 1]
        if key not in time_values_clock_stopped.keys():
            for i in range(min_seconds, max_seconds + 1):
                clock_stopped_stats.append(0)
        else:
            mean = np.mean(time_values_clock_stopped[key])
            std = np.std(time_values_clock_stopped[key])
            if std == 0:
                for i in range(min_seconds, max_seconds + 1):
                    if i == time_values_clock_stopped[key][0]:
                        clock_stopped_stats.append(1)
                    else:
                        clock_stopped_stats.append(0)
            else:
                norm_dist = norm(loc=mean, scale=std)
                for i in range(min_seconds, max_seconds + 1):
                    if i == min_seconds:
                        clock_stopped_stats.append(
                            norm_dist.cdf(min_seconds + 0.5))
                    elif i == max_seconds:
                        clock_stopped_stats.append(
                            1 - norm_dist.cdf(max_seconds - 0.5))
                    else:
                        clock_stopped_stats.append(
                            norm_dist.cdf(i+0.5) - norm_dist.cdf(i-0.5))

        time_df.loc[num_calculated] = clock_stopped_stats
        num_calculated += 1

        # Clock not stopped stats
        clock_not_stopped_stats = [key, 0]
        if key not in time_values_clock_not_stopped.keys():
            for i in range(min_seconds, max_seconds + 1):
                clock_not_stopped_stats.append(0)
        else:
            mean = np.mean(time_values_clock_not_stopped[key])
            std = np.std(time_values_clock_not_stopped[key])
            if std == 0:
                for i in range(min_seconds, max_seconds + 1):
                    if i == time_values_clock_not_stopped[key][0]:
                        clock_not_stopped_stats.append(1)
                    else:
                        clock_not_stopped_stats.append(0)
            else:
                norm_dist = norm(loc=mean, scale=std)
                for i in range(min_seconds, max_seconds + 1):
                    if i == min_seconds:
                        clock_not_stopped_stats.append(
                            norm_dist.cdf(min_seconds + 0.5))
                    elif i == max_seconds:
                        clock_not_stopped_stats.append(
                            1 - norm_dist.cdf(max_seconds-0.5))
                    else:
                        clock_not_stopped_stats.append(
                            norm_dist.cdf(i + 0.5) - norm_dist.cdf(i-0.5))
        time_df.loc[num_calculated] = clock_not_stopped_stats
        num_calculated += 1

    time_df.to_csv("processed_data/time_stats_2022.csv")

    # Save punt time data to csv
    min_seconds = math.inf
    max_seconds = 0
    for key in punt_times.keys():
        key_min = min(punt_times[key])
        key_max = max(punt_times[key])
        if key_min < min_seconds:
            min_seconds = key_min
        if key_max > max_seconds:
            max_seconds = key_max

    min_seconds = int(min_seconds)
    max_seconds = int(max_seconds)

    columns = ["Yards Gained"]
    for secs in range(min_seconds, max_seconds+1):
        columns.append(f"{secs} secs")
    punt_time_df = pd.DataFrame(columns=columns)

    num_calculated = 0
    for key in punt_times.keys():
        punt_time_entry = [key]
        mean = np.mean(punt_times[key])
        std = np.std(punt_times[key])
        if std == 0:
            for i in range(min_seconds, max_seconds + 1):
                if i == punt_times[key][0]:
                    punt_time_entry.append(1)
                else:
                    punt_time_entry.append(0)
        else:
            dist = norm(loc=mean, scale=std)
            for i in range(min_seconds, max_seconds + 1):
                if i == min_seconds:
                    punt_time_entry.append(dist.cdf(min_seconds + 0.5))
                elif i == max_seconds:
                    punt_time_entry.append(dist.cdf(max_seconds - 0.5))
                else:
                    punt_time_entry.append(
                        dist.cdf(i + 0.5) - dist.cdf(i - 0.5))

        punt_time_df.loc[num_calculated] = punt_time_entry
        num_calculated += 1
    punt_time_df.to_csv("processed_data/punt_time_stats_2022.csv")

    # Save field goal time stats to csv
    min_seconds = math.inf
    max_seconds = 0
    for key in field_goal_times.keys():
        if len(field_goal_times[key]) == 0:
            continue
        key_min = min(field_goal_times[key])
        key_max = max(field_goal_times[key])
        if key_min < min_seconds:
            min_seconds = key_min
        else:
            max_seconds = key_max

    min_seconds = int(min_seconds)
    max_seconds = int(max_seconds)

    columns = ["Field Section"]
    for i in range(min_seconds, max_seconds + 1):
        columns.append(f"{i} secs")
    field_goal_time_df = pd.DataFrame(columns=columns)

    num_calculated = 0
    for key in field_goal_times.keys():
        field_goal_time_entry = [key]
        if len(field_goal_times[key]) == 0:
            for i in range(min_seconds, max_seconds + 1):
                field_goal_time_entry.append(0)
        else:
            mean = np.mean(field_goal_times[key])
            std = np.std(field_goal_times[key])
            if std == 0:
                for i in range(min_seconds, max_seconds + 1):
                    if i == field_goal_times[key]:
                        field_goal_time_entry.append(1)
                    else:
                        field_goal_time_entry.append(0)
            else:
                dist = norm(loc=mean, scale=std)
                for i in range(min_seconds, max_seconds + 1):
                    if i == min_seconds:
                        field_goal_time_entry.append(
                            dist.cdf(min_seconds + 0.5))
                    elif i == max_seconds:
                        field_goal_time_entry.append(
                            dist.cdf(max_seconds - 0.5))
                    else:
                        field_goal_time_entry.append(
                            dist.cdf(i + 0.5) - dist.cdf(i - 0.5))

        field_goal_time_df.loc[num_calculated] = field_goal_time_entry
        num_calculated += 1
    field_goal_time_df.to_csv("processed_data/field_goal_time_2022.csv")

    """
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
                yards_gained[down, starting_section,
                             timeout_used].append(row['yards_gained'])
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
        """
    return

    # Time probabilities (dependent on yards gained)
    print(f"Longest play (not including last plays): {longest_play}")
    max_length_play = 0
    for key in time_values.keys():
        if max(time_values[key]) > max_length_play:
            max_length_play = max(time_values[key])

    print(f"Max length play: {max_length_play}")

    # Create transition probabilities
    stats_df = pd.DataFrame(columns=['Down', 'Field Section', 'Timeout Used', 'T-0',
                                     'T-1', 'T-2', 'T-3', 'T-4', 'T-5', 'T-6', 'T-7', 'T-8', 'T-9', 'T-10', 'T-11'])

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
                        probs.append(normal_dist.cdf(
                            (end_section - section)*10 + 5) - normal_dist.cdf((end_section - section)*10 - 5))

                df_entry = [down, section, timeout] + probs
                stats_df.loc[num_calculated] = df_entry

                num_calculated += 1

    stats_df.to_csv('stats.csv')

    punt_return_df = pd.DataFrame(columns=["Mean", "Average"])
    punt_return_df.loc[1] = [np.mean(punt_yards) - np.mean(punt_return_yards), np.sqrt(
        np.std(punt_yards)**2 + np.std(punt_return_yards)**2)]
    punt_return_df.to_csv('punt_stats.csv')

    # Create field goal data
    field_goal_df = pd.DataFrame(
        columns=['T-1', 'T-2', 'T-3', 'T-4', 'T-5', 'T-6', 'T-7', 'T-8', 'T-9', 'T-10'])
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
