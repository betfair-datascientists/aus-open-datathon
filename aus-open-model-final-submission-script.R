# This script will outline an example of creating a tennis model and creating predictions using the final dataset
# Predictions will be created for both the mens and womens draw

# Import libraries
library(dplyr)
library(readr)
library(tidyr)
library(corrr)
library(highcharter)
library(RcppRoll)
library(tidyselect)
library(lubridate)
library(stringr)
library(zoo)
library(purrr)
library(h2o)

##########################
#### Define functions ####
##########################

split_winner_loser_columns <- function(df) {
  # This function splits the raw data into two dataframes and appends them together then shuffles them
  # This output is a dataframe with only one player's stats on each row
  # Grab a df with only the Winner's stats
  winner = df %>% 
    select(-contains("Loser")) %>% # Select only the Winner columns + extra game info columns as a df
    rename_at( # Rename all columns containing "Winner" to "Player" 
      vars(contains("Winner")),
      ~str_replace(., "Winner", "Player")
    ) %>%
    mutate(Winner = 1) # Create a target column
  
  # Repeat the process with the loser's stats
  loser = df %>%
    select(-contains("Winner")) %>%
    rename_at(
      vars(contains("Loser")),
      ~str_replace(., "Loser", "Player")
    ) %>%
    mutate(Winner = 0)
  
  set.seed(183) # Set seed to replicate results - 183 is the most games played in a tennis match (Isner-Mahut)
  
  # Create a df that appends both the Winner and loser df together
  combined_df = winner %>% 
    rbind(loser) %>% # Append the loser df to the Winner df
    slice(sample(1:n())) %>% # Randomise row order
    arrange(Match_Id) %>% # Arrange by Match_Id
    return()
}


gather_df <- function(df) {
  # This function puts the df back into its original format of each row containing stats for both players
  df %>%
    arrange(Match_Id) %>%
    filter(row_number() %% 2 != 0) %>% # Filter for every 2nd row, starting at the 1st index. e.g. 1, 3, 5
    rename_at( # Rename columns to player_1
      vars(contains("Player")),
      ~str_replace(., "Player", "player_1")
    ) %>%
    inner_join(df %>%
                 filter(row_number() %% 2 == 0) %>%
                 rename_at(
                   vars(contains("Player")), # Rename columns to player_2
                   ~str_replace(., "Player", "player_2")
                 ) %>%
                 select(Match_Id, contains("Player")),
               by=c('Match_Id')
    ) %>%
    select(Match_Id, player_1, player_2, Winner, everything()) %>%
    return()
}


add_ratio_features <- function(df) {
  # This function adds ratio features to the appended df
  df %>%
    mutate(
      F_Player_Serve_Win_Ratio = (Player_FirstServes_Won + Player_SecondServes_Won - Player_DoubleFaults) / 
        (Player_FirstServes_In + Player_SecondServes_In + Player_DoubleFaults), # Point Win ratio when serving
      F_Player_Return_Win_Ratio = Player_ReturnPoints_Won / Player_ReturnPoints_Faced, # Point win ratio when returning
      F_Player_BreakPoints_Per_Game = Player_BreakPoints / Total_Games, # Breakpoints per receiving game
      F_Player_Game_Win_Percentage = Player_Games_Won / Total_Games
    ) %>%
    mutate_at(
      vars(colnames(.), -contains("Rank"), -Tournament_Date),
      ~ifelse(is.na(.), 0, .)
    ) %>%
    return()
}


clean_missing_data = function(df) {
  # This function cleans missing data
  df %>%
    mutate(
      Winner_ReturnPoints_Faced = ifelse(is.na(Winner_ReturnPoints_Faced), Loser_FirstServes_In + Loser_SecondServes_In, Winner_ReturnPoints_Faced),
      Winner_ReturnPoints_Won = ifelse(is.na(Winner_ReturnPoints_Won), Winner_ReturnPoints_Faced - Loser_FirstServes_Won - Loser_SecondServes_Won, Winner_ReturnPoints_Won),
      Loser_ReturnPoints_Faced = ifelse(is.na(Loser_ReturnPoints_Faced), Winner_FirstServes_In + Winner_SecondServes_In, Winner_ReturnPoints_Faced),
      Loser_ReturnPoints_Won = ifelse(is.na(Loser_ReturnPoints_Won), Loser_ReturnPoints_Faced - Winner_FirstServes_Won - Winner_SecondServes_Won, Loser_ReturnPoints_Won),
      Winner_Aces = ifelse(is.na(Winner_Aces), mean(Winner_Aces, na.rm = TRUE), Winner_Aces),
      Loser_Aces = ifelse(is.na(Loser_Aces), mean(Loser_Aces, na.rm = TRUE), Loser_Aces),
      Winner_DoubleFaults = ifelse(is.na(Winner_DoubleFaults), mean(Winner_DoubleFaults, na.rm = TRUE), Winner_DoubleFaults),
      Loser_DoubleFaults = ifelse(is.na(Loser_DoubleFaults), mean(Loser_DoubleFaults, na.rm = TRUE), Loser_DoubleFaults),
      Winner_Rank = ifelse(is.na(Winner_Rank), 999, Winner_Rank),
      Loser_Rank = ifelse(is.na(Loser_Rank), 999, Loser_Rank)
    ) %>%
    mutate_at(
      vars(-contains("Rank"), -"Tournament_Date"),
      ~ifelse(is.na(.), 0, .)
    )
  
}


extract_latest_features_for_tournament = function(df, dte) {
  # This function extracts the latest features for tournaments (features before the tournament)
  df %>%
    filter(Tournament_Date == dte, Round_Description == "First Round", Tournament_Date != "2012-01-16") %>%
    group_by(Player) %>%
    select_at(
      vars(Match_Id, starts_with("F_"), Player_Rank)
    ) %>%
    rename(F_Player_Rank = Player_Rank) %>%
    ungroup() %>%
    mutate(Feature_Date = dte) %>%
    select(Player, Feature_Date, everything())
  
}


##############################
#### Create training data ####
##############################

# Read in men and womens data; randomise the data to avoid result leakage
mens = readr::read_csv('data/ATP_data_10Jan.csv', na = ".") %>%
  filter(Court_Surface == "Hard" | Court_Surface == "Indoor Hard") %>%
  mutate(Match_Id = row_number(), # Add a match ID column to be used as a key
         Tournament_Date = dmy(Tournament_Date), # Change Tournament to datetime
         Total_Games = Winner_Games_Won + Loser_Games_Won) %>% # Add a total games played column
  split_winner_loser_columns() %>% # Change the dataframe from wide to long
  add_ratio_features() %>% # Add features
  group_by(Player) %>%
  mutate_at( # Create a rolling mean with window 15 for each player. If the player hasn't played 15 games, use a cumulative mean
    vars(starts_with("F_")),
    ~coalesce(rollmean(., k = 15, align = "right", fill = NA_real_), cummean(.)) %>% lag()
  ) %>%
  ungroup()

womens = readr::read_csv('data/ATP_data_10Jan.csv', na = ".") %>%
  filter(Court_Surface == "Hard" | Court_Surface == "Indoor Hard") %>%
  mutate(Match_Id = row_number(), # Add a match ID column to be used as a key
         Tournament_Date = dmy(Tournament_Date), # Change Tournament to datetime
         Total_Games = Winner_Games_Won + Loser_Games_Won) %>% # Add a total games played column
  split_winner_loser_columns() %>% # Change the dataframe from wide to long
  add_ratio_features() %>% # Add features
  group_by(Player) %>%
  mutate_at( # Create a rolling mean with window 15 for each player. If the player hasn't played 15 games, use a cumulative mean
    vars(starts_with("F_")),
    ~coalesce(rollmean(., k = 15, align = "right", fill = NA_real_), cummean(.)) %>% lag()
  ) %>%
  ungroup()


# Create a df of only aus open and us open results for both mens and womens results
aus_us_open_results_mens = 
  mens %>%
  filter((Tournament == "Australian Open, Melbourne" | Tournament == "U.S. Open, New York") 
         & Round_Description != "Qualifying" & Tournament_Date != "2012-01-16") %>%
  select(Match_Id, Player, Tournament, Tournament_Date, Round_Description, Winner)

aus_us_open_results_womens = 
  womens %>%
  filter((Tournament == "Australian Open, Melbourne" | Tournament == "U.S. Open, New York") 
         & Round_Description != "Qualifying" & Tournament_Date != "2012-01-16") %>%
  select(Match_Id, Player, Tournament, Tournament_Date, Round_Description, Winner)


# Convert the feature matrix to long format
feature_matrix_long_mens = 
  aus_us_open_results_mens %>%
  distinct(Tournament_Date) %>%
  pull() %>%
  map_dfr(
    ~extract_latest_features_for_tournament(mens, .)
  ) %>%
  filter(Feature_Date != "2012-01-16") %>% # Filter out the first Aus open as we don't have enough data before it
  mutate_at( # Replace NAs with the mean
    vars(starts_with("F_")),
    ~ifelse(is.na(.), mean(., na.rm = TRUE), .)
  )

feature_matrix_long_womens = 
  aus_us_open_results_womens %>%
  distinct(Tournament_Date) %>%
  pull() %>%
  map_dfr(
    ~extract_latest_features_for_tournament(womens, .)
  ) %>%
  filter(Feature_Date != "2012-01-16") %>% # Filter out the first Aus open as we don't have enough data before it
  mutate_at( # Replace NAs with the mean
    vars(starts_with("F_")),
    ~ifelse(is.na(.), mean(., na.rm = TRUE), .)
  )

# Joining results to features
feature_matrix_wide_mens = aus_us_open_results_mens %>%
  inner_join(feature_matrix_long_mens %>% 
               select(-Match_Id), 
             by = c("Player", "Tournament_Date" = "Feature_Date")) %>%
  gather_df() %>%
  mutate(
    F_Serve_Win_Ratio_Diff = F_player_1_Serve_Win_Ratio - F_player_2_Serve_Win_Ratio,
    F_Return_Win_Ratio_Diff = F_player_1_Return_Win_Ratio - F_player_2_Return_Win_Ratio,
    F_Game_Win_Percentage_Diff = F_player_1_Game_Win_Percentage - F_player_2_Game_Win_Percentage,
    F_BreakPoints_Per_Game_Diff = F_player_1_BreakPoints_Per_Game - F_player_2_BreakPoints_Per_Game,
    F_Rank_Diff = (F_player_1_Rank - F_player_2_Rank),
    Winner = as.factor(Winner)
  ) %>%
  select(Match_Id, player_1, player_2, Tournament, Tournament_Date, Round_Description, Winner, everything())

feature_matrix_wide_womens = aus_us_open_results_womens %>%
  inner_join(feature_matrix_long_womens %>% 
               select(-Match_Id), 
             by = c("Player", "Tournament_Date" = "Feature_Date")) %>%
  gather_df() %>%
  mutate(
    F_Serve_Win_Ratio_Diff = F_player_1_Serve_Win_Ratio - F_player_2_Serve_Win_Ratio,
    F_Return_Win_Ratio_Diff = F_player_1_Return_Win_Ratio - F_player_2_Return_Win_Ratio,
    F_Game_Win_Percentage_Diff = F_player_1_Game_Win_Percentage - F_player_2_Game_Win_Percentage,
    F_BreakPoints_Per_Game_Diff = F_player_1_BreakPoints_Per_Game - F_player_2_BreakPoints_Per_Game,
    F_Rank_Diff = (F_player_1_Rank - F_player_2_Rank),
    Winner = as.factor(Winner)
  ) %>%
  select(Match_Id, player_1, player_2, Tournament, Tournament_Date, Round_Description, Winner, everything())


###################################
#### Create 2019 features data ####
###################################

# Let's create features for both men and women using the past 15 games that they have played

# Get the last 15 games played for each unique player
unique_players_mens = read_csv('data/men_dummy_submission_file.csv') %>% pull(player_1) %>% unique()
unique_players_womens = read_csv('data/women_dummy_submission_file.csv') %>% pull(player_1) %>% unique()

# Create a feature table for both mens and womens
lookup_feature_table_mens = read_csv('data/ATP_data_10Jan.csv', na = ".") %>%
  filter(Court_Surface == "Hard" | Court_Surface == "Indoor Hard") %>%
  mutate(Match_Id = row_number(), # Add a match ID column to be used as a key
         Tournament_Date = dmy(Tournament_Date), # Change Tournament to datetime
         Total_Games = Winner_Games_Won + Loser_Games_Won) %>% # Add a total games played column
  split_winner_loser_columns() %>% # Change the dataframe from wide to long
  add_ratio_features() %>%
  filter(Player %in% unique_players_mens) %>%
  group_by(Player) %>%
  top_n(15, Match_Id) %>%
  summarise(
    F_Player_Serve_Win_Ratio = mean(F_Player_Serve_Win_Ratio),
    F_Player_Return_Win_Ratio = mean(F_Player_Return_Win_Ratio),
    F_Player_BreakPoints_Per_Game = mean(F_Player_BreakPoints_Per_Game),
    F_Player_Game_Win_Percentage = mean(F_Player_Game_Win_Percentage),
    F_Player_Rank = last(Player_Rank)
  )

# Create a feature table for both mens and womens
lookup_feature_table_womens = read_csv('data/WTA_data_10Jan.csv', na = ".") %>%
  filter(Court_Surface == "Hard" | Court_Surface == "Indoor Hard") %>%
  mutate(Match_Id = row_number(), # Add a match ID column to be used as a key
         Tournament_Date = dmy(Tournament_Date), # Change Tournament to datetime
         Total_Games = Winner_Games_Won + Loser_Games_Won) %>% # Add a total games played column
  split_winner_loser_columns() %>% # Change the dataframe from wide to long
  add_ratio_features() %>%
  filter(Player %in% unique_players_womens) %>%
  group_by(Player) %>%
  top_n(15, Match_Id) %>%
  summarise(
    F_Player_Serve_Win_Ratio = mean(F_Player_Serve_Win_Ratio),
    F_Player_Return_Win_Ratio = mean(F_Player_Return_Win_Ratio),
    F_Player_BreakPoints_Per_Game = mean(F_Player_BreakPoints_Per_Game),
    F_Player_Game_Win_Percentage = mean(F_Player_Game_Win_Percentage),
    F_Player_Rank = last(Player_Rank)
  )


# Create a feature matrix for all the player_1s by joining to the lookup feature table on name
draw_player_1_mens = read_csv('data/men_dummy_submission_file.csv') %>%
  select(player_1) %>%
  inner_join(lookup_feature_table_mens, by=c("player_1" = "Player")) %>%
  rename(F_player_1_Serve_Win_Ratio = F_Player_Serve_Win_Ratio,
         F_player_1_Return_Win_Ratio = F_Player_Return_Win_Ratio,
         F_player_1_BreakPoints_Per_Game = F_Player_BreakPoints_Per_Game,
         F_player_1_Game_Win_Percentage = F_Player_Game_Win_Percentage,
         F_player_1_Rank = F_Player_Rank)

draw_player_1_womens = read_csv('data/women_dummy_submission_file.csv') %>%
  select(player_1) %>%
  inner_join(lookup_feature_table_womens, by=c("player_1" = "Player")) %>%
  rename(F_player_1_Serve_Win_Ratio = F_Player_Serve_Win_Ratio,
         F_player_1_Return_Win_Ratio = F_Player_Return_Win_Ratio,
         F_player_1_BreakPoints_Per_Game = F_Player_BreakPoints_Per_Game,
         F_player_1_Game_Win_Percentage = F_Player_Game_Win_Percentage,
         F_player_1_Rank = F_Player_Rank)

# Create a feature matrix for all the player_2s by joining to the lookup feature table on name
draw_player_2_mens = read_csv('data/men_dummy_submission_file.csv') %>%
  select(player_2) %>%
  inner_join(lookup_feature_table_mens, by=c("player_2" = "Player")) %>%
  rename(F_player_2_Serve_Win_Ratio = F_Player_Serve_Win_Ratio,
         F_player_2_Return_Win_Ratio = F_Player_Return_Win_Ratio,
         F_player_2_BreakPoints_Per_Game = F_Player_BreakPoints_Per_Game,
         F_player_2_Game_Win_Percentage = F_Player_Game_Win_Percentage,
         F_player_2_Rank = F_Player_Rank)

draw_player_2_womens = read_csv('data/women_dummy_submission_file.csv') %>%
  select(player_2) %>%
  inner_join(lookup_feature_table_womens, by=c("player_2" = "Player")) %>%
  rename(F_player_2_Serve_Win_Ratio = F_Player_Serve_Win_Ratio,
         F_player_2_Return_Win_Ratio = F_Player_Return_Win_Ratio,
         F_player_2_BreakPoints_Per_Game = F_Player_BreakPoints_Per_Game,
         F_player_2_Game_Win_Percentage = F_Player_Game_Win_Percentage,
         F_player_2_Rank = F_Player_Rank)

# Bind the two dfs together and only select the players' names and features (which start with 'F_' for simplicity)
aus_open_2019_features_mens = draw_player_1_mens %>% 
  bind_cols(draw_player_2_mens) %>%
  select(player_1, player_2, everything()) %>%
  mutate(
    F_Serve_Win_Ratio_Diff = F_player_1_Serve_Win_Ratio - F_player_2_Serve_Win_Ratio,
    F_Return_Win_Ratio_Diff = F_player_1_Return_Win_Ratio - F_player_2_Return_Win_Ratio,
    F_Game_Win_Percentage_Diff = F_player_1_Game_Win_Percentage - F_player_2_Game_Win_Percentage,
    F_BreakPoints_Per_Game_Diff = F_player_1_BreakPoints_Per_Game - F_player_2_BreakPoints_Per_Game,
    F_Rank_Diff = (F_player_1_Rank - F_player_2_Rank)
  ) %>%
  select(player_1, player_2, contains("Diff"))

aus_open_2019_features_womens = draw_player_1_womens %>% 
  bind_cols(draw_player_2_womens) %>%
  select(player_1, player_2, everything()) %>%
  mutate(
    F_Serve_Win_Ratio_Diff = F_player_1_Serve_Win_Ratio - F_player_2_Serve_Win_Ratio,
    F_Return_Win_Ratio_Diff = F_player_1_Return_Win_Ratio - F_player_2_Return_Win_Ratio,
    F_Game_Win_Percentage_Diff = F_player_1_Game_Win_Percentage - F_player_2_Game_Win_Percentage,
    F_BreakPoints_Per_Game_Diff = F_player_1_BreakPoints_Per_Game - F_player_2_BreakPoints_Per_Game,
    F_Rank_Diff = (F_player_1_Rank - F_player_2_Rank)
  ) %>%
  select(player_1, player_2, contains("Diff"))


#########################
#### Train the model ####
#########################

## Setup H2O
h2o.init(ip = "localhost",
         port = 54321,
         enable_assertions = TRUE,
         nthreads = 5,
         max_mem_size = "24g"
)


## Sending file to h2o
train_mens_h2o = feature_matrix_wide_mens %>%
  select(contains("Diff"), Winner) %>%
  as.h2o(destination_frame = "train_h2o_mens")

train_womens_h2o = feature_matrix_wide_womens %>%
  select(contains("Diff"), Winner) %>%
  as.h2o(destination_frame = "train_h2o_womens")

aus_open_2019_features_mens_h2o = aus_open_2019_features_mens %>%
  select(contains("Diff")) %>%
  as.h2o(destination_frame = "aus_open_2019_features_h2o_mens")

aus_open_2019_features_womens_h2o = aus_open_2019_features_womens %>%
  select(contains("Diff")) %>%
  as.h2o(destination_frame = "aus_open_2019_features_h2o_womens")

## Run Auto ML 
mens_model = h2o.automl(y = "Winner",
                          training_frame = train_mens_h2o,
                          max_runtime_secs = 30,
                          max_models = 100,
                          stopping_metric = "logloss",
                          sort_metric = "logloss",
                          balance_classes = TRUE,
                          seed = 183) # Set seed to replicate results - 183 is the most games played in a tennis match (Isner-Mahut)

womens_model = h2o.automl(y = "Winner",
                          training_frame = train_womens_h2o,
                          max_runtime_secs = 30,
                          max_models = 100,
                          stopping_metric = "logloss",
                          sort_metric = "logloss",
                          balance_classes = TRUE,
                          seed = 183) # Set seed to replicate results - 183 is the most games played in a tennis match (Isner-Mahut)

## Predictions on test frame
mens_predictions = h2o.predict(mens_model@leader, aus_open_2019_features_mens_h2o) %>%
  as.data.frame()

womens_predictions = h2o.predict(womens_model@leader, aus_open_2019_features_womens_h2o) %>%
  as.data.frame()

# Add predictions to the df
aus_open_2019_features_mens$player_1_win_probability = mens_predictions$p1
aus_open_2019_features_womens$player_1_win_probability = womens_predictions$p1

# Create submission df
mens_submission = aus_open_2019_features_mens %>%
  select(player_1,
         player_2,
         player_1_win_probability)

womens_submission = aus_open_2019_features_womens %>%
  select(player_1,
         player_2,
         player_1_win_probability)

# Export to CSV
mens_submission %>% write_csv("mens_submission_YOUR_SUBMISSION_NAME_HERE.csv")
womens_submission %>% write_csv("womens_submission_YOUR_SUBMISSION_NAME_HERE.csv")


## Find the players who are in the dummy submissions file but not in the mens dataset
unique_mens_players_submissions =  read_csv('data/men_dummy_submission_file.csv') %>%
  pull(player_1) %>%
  unique()


unique_mens_players_submissions[!unique_mens_players_submissions %in% mens$Player]

unique_womens_players_submissions =  read_csv('data/women_dummy_submission_file.csv') %>%
  pull(player_1) %>%
  unique()

unique_womens_players_submissions[!unique_womens_players_submissions %in% womens$Player]