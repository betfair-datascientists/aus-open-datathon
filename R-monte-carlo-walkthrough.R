library(tidyverse)
library(janitor)
library(furrr)
library(lubridate)
library(MLmetrics)
library(glue)

# Load the data -----------------------------------------------------------

# Read CSV
mens = read_csv("ATP_matches_Jan_10.csv", na = ".")

# Clean names
mens = mens %>% clean_names()

# Split and append data -----------------------------------------------------------

# Data Attributes for the winner of a match
winner = 
    mens %>%
    mutate(
        serve_points_total = loser_return_points_faced,
        serve_points_won = winner_first_serves_won + winner_second_serves_won
    ) %>%
    select(
        player = winner,
        tournament, tournament_date, court_surface, round_description,
        serve_points_total, serve_points_won,
        return_points_total = winner_return_points_faced,
        return_points_won = winner_return_points_won
    )

# Data Attributes for the loser of a match
loser = 
    mens %>%
    mutate(
        serve_points_total = winner_return_points_faced,
        serve_points_won = loser_first_serves_won + loser_second_serves_won
    ) %>%
    select(
        player = loser,
        tournament, tournament_date, court_surface, round_description,
        serve_points_total, serve_points_won,
        return_points_total = loser_return_points_faced,
        return_points_won = loser_return_points_won
    )

# Append and filter out nas
player_set = winner %>% union_all(loser)
player_set = player_set[complete.cases(player_set),]


# Player point based win rates -----------------------------------------------------------

# Calculate a players empirical win rates for service and return points
point_win_rates = 
    player_set %>%
    select(-(tournament:round_description)) %>%
    group_by(player) %>%
    summarise_all(sum, na.rm = TRUE) %>%
    mutate(
        serve_win_rate = serve_points_won / serve_points_total,
        return_win_rate = return_points_won / return_points_total,
        total_points_sample = serve_points_total + return_points_total
    ) %>%
    select(player, total_points_sample, serve_win_rate, return_win_rate) %>%
    arrange(desc(total_points_sample))

# Simulation Functions -----------------------------------------------------------

# DESCRIPTION:
# The following chunks of code is the lengthy logic required to simulate a match
# The code's broken into the semantic game segments (match, set, game, point)
# Most of the logic is required to handle the intricacies of a tennis match (tiebreaks, deuce, set length etc) so it's not important to read

# IF YOU DON'T CARE YOU SHOULD HEAD TO LINE 310 to pick back up
simulate_match = function(serve_win_vec, return_win_vec, sets = 5) {
    
    # Set count
    sets_needed = ifelse(sets == 5, 3, 2)
    
    matchScore = tibble(p1 = 0, p2 = 0)
    
    # Anyone won?
    while (max(matchScore$p1, matchScore$p2) < sets_needed) {
        
        # Serve starter
        if (sum(matchScore$p1, matchScore$p2) == 0) {
            start_server = sample(c("p1", "p2"), 1)
        } else {
            start_server = ifelse(set_result[[2]]=="p1", "p2", "p1")
        }
        
        #simulate set
        set_result = simulate_set(serve_win_vec, return_win_vec, start_server = start_server)
        
        if (set_result[[1]] == 1) {
            matchScore$p1 = matchScore$p1 + 1
        } else {
            matchScore$p2 = matchScore$p2 + 1
        }
        
    }
    
    if (matchScore$p1 == sets_needed) {
        return(1)
    } else {
        return(0)
    }
    
}


simulate_set = function(serve_win_vec, return_win_vec, start_server = "p1") {
    
    # Score
    setScore = tibble(p1 = 0, p2 = 0)
    
    # Anyone won?
    while (check_set_winner(setScore) == 0) {
        
        if (sum(setScore$p1, setScore$p2) == 0) {
            game_server = start_server
        } else {
            game_server = ifelse(game_server=="p1", "p2", "p1")
        }
        
        #print(game_server)
        
        if (sum(setScore$p1, setScore$p2) < 12) {
            # Regular game
            server_wins = simulate_game(serve_win_vec, return_win_vec, serving = game_server,  tiebreak = FALSE)
        } else {
            # Tie break
            server_wins = simulate_game(serve_win_vec, return_win_vec, serving = game_server, tiebreak = TRUE)
        }
        
        #print(p1_game)
        
        if (game_server == "p1") {
    
            if (server_wins==1) {
                setScore$p1 = setScore$p1 + 1
            } else {
                setScore$p2 = setScore$p2 + 1
            }
        } else {
            if (server_wins==1) {
                setScore$p2 = setScore$p2 + 1
            } else {
                setScore$p1 = setScore$p1 + 1
            }
            
        }
        
    }
    
    setwinner = check_set_winner(setScore)
    
    print(setScore)
    
    if (setwinner == 1) {
        return(list(1, game_server))   
    } else {
        return(list(0, game_server))
    }
    
}


simulate_game = function(serve_win_vec, return_win_vec, serving = "p1", tiebreak = FALSE) {
    
    # Score
    gameScore = tibble(p1 = 0, p2 = 0)
    
    if (!tiebreak) {
    
        # Anyone won?
        while (check_game_winner(gameScore) == 0) {
            
            # Did p1 win?
            p1_game =  simulate_point(serve_win_vec, return_win_vec, serving = serving)

            # How to adjust scores
            if (sum(gameScore$p1, gameScore$p2) == 7) {
                
                if (gameScore$p1 == 4) {
                    if (p1_game == 1){
                        gameScore$p1 = gameScore$p1 + 1
                    } else {
                        gameScore$p1 = gameScore$p1 - 1
                    }
                } else {
                    if (p1_game == 1){
                        gameScore$p2 = gameScore$p2 - 1
                    } else {
                        gameScore$p2 = gameScore$p2 + 1
                    }
                }
            } else {
                if (p1_game == 1){
                    gameScore$p1 = gameScore$p1 + 1
                } else {
                    gameScore$p2 = gameScore$p2 + 1
                }
            }
        }
    } else {
        
        # Anyone won?
        while (check_game_winner(gameScore, tiebreak = TRUE) == 0) {
            
            # Who's serving
            if ((sum(gameScore$p1, gameScore$p2) %% 3) %in% c(0,1)) {
                tie_server = serving
            } else {
                tie_server = ifelse(serving=="p1", "p2", "p1")
            }
            
            # Did p1 win?
            p1_game =  simulate_point(serve_win_vec, return_win_vec, serving = tie_server)

            # Adjust scores
            if (p1_game == 1){
                gameScore$p1 = gameScore$p1 + 1
            } else {
                gameScore$p2 = gameScore$p2 + 1
            }
        }
    }
    
    if (gameScore$p1 > gameScore$p2) {
        return(1)
    } else {
        return(0)
    }
    
}

simulate_point = function(serve_win_vec, return_win_vec, serving = "p1") {
    
    if (serving == "p1") {
        x = serve_win_vec[1]
        y = 1 - return_win_vec[2]
        z = mean(c(x, y))
    } else {
        x = serve_win_vec[2]
        y = 1 - return_win_vec[1]
        z = mean(c(x, y))
    }
    
    rando = runif(1,0,1)

    if (rando < z) {
        return(1)
    } else {
        return(0)
    }
    
}
    
    
    

# Simulation Utilities 
check_set_winner = function(setScore) {
    
    p1 = setScore$p1
    p2 = setScore$p2
    
    if (max(p1, p2) < 6) {
        return(0)
    } else if (max(p1, p2) == 6 & sum(p1, p2) %in% c(11,12)) {
        return(0)
    } else {
        if (p1 > p2) {
            return(1)
        } else {
            return(-1)
        }
    }
}

check_game_winner = function(gameScore, tiebreak = FALSE) {
    
    p1 = gameScore$p1
    p2 = gameScore$p2
    
    if (tiebreak) {
        if (p1-1 > p2 & p1 >= 7) {
            return(1)
        }
        if (p2-1 > p1 & p2 >= 7) {
            return(-1)
        }
        return(0)
    } else {
        if (p1-1 > p2 & p1 >= 4) {
            return(1)
        }
        if (p2-1 > p1 & p2 >= 4) {
            return(-1)
        }
        return(0)
    }
}


# Simulate a matchup -----------------------------------------------------------

# Welcome back

# Let's try our functions out and simulate a few matches between Roger Federer and Novak Djokovic
player_1 = "Roger Federer"
player_2 = "Novak Djokovic"

serve_win_vec = c(
    point_win_rates %>% filter(player == player_1) %>% pull(serve_win_rate),
    point_win_rates %>% filter(player == player_2) %>% pull(serve_win_rate)
)

return_win_vec = c(
    point_win_rates %>% filter(player == player_1) %>% pull(return_win_rate),
    point_win_rates %>% filter(player == player_2) %>% pull(return_win_rate)
)

# The sims are very slow so let's utilise parallel processing from the furrr package
plan(multiprocess)
p1_win_vector = 
    seq(1,1000) %>%
    future_map_dbl(~simulate_match(serve_win_vec, return_win_vec))

print(glue("Roger's win prob: {(p1_win_vector %>% mean()) * 100 %>% round()} %"))

#45.5 % which is pretty intuitive

# Create helpful functions -----------------------------------------------------------

# We'll create this wrapper so it's more easy to execute a two player simulation like the one we did above
simulate_matchup = function(winRates, player_1, player_2, number_of_sims = 400) {
    
    # Missing player?
    if (winRates %>% filter(player == player_1) %>% nrow() == 0) {
        p1_serve = median(winRates$serve_win_rate)
        p1_return = median(winRates$return_win_rate)
    } else {
        p1_serve = winRates %>% filter(player == player_1) %>% pull(serve_win_rate)
        p1_return = winRates %>% filter(player == player_1) %>% pull(return_win_rate)
    }
    
    if (winRates %>% filter(player == player_2) %>% nrow() == 0) {
        p2_serve = median(winRates$serve_win_rate)
        p2_return = median(winRates$return_win_rate)
    } else {
        p2_serve = winRates %>% filter(player == player_2) %>% pull(serve_win_rate)
        p2_return = winRates %>% filter(player == player_2) %>% pull(return_win_rate)
    }
    
    serve_win_vec = c(p1_serve, p2_serve)
    return_win_vec = c(p1_return, p2_return)
    
    # Run simulation
    seq(1, number_of_sims) %>%
    future_map_dbl(~simulate_match(serve_win_vec, return_win_vec)) %>%
    mean()
    
}

# We'll create another wrapper so it's more easy to calculate some custom point winrates for men's and women's dataframes
calculate_player_winrates = function(rawdf, tournament_name = NULL, year = NULL, years_before = 1) {
    
    # Data Attributes for the winner of a match
    winner = 
        rawdf %>%
        mutate(
            serve_points_total = loser_return_points_faced,
            serve_points_won = winner_first_serves_won + winner_second_serves_won
        ) %>%
        select(
            player = winner,
            tournament, tournament_date, court_surface, round_description,
            serve_points_total, serve_points_won,
            return_points_total = winner_return_points_faced,
            return_points_won = winner_return_points_won
        )
    
    # Data Attributes for the loser of a match
    loser = 
        rawdf %>%
        mutate(
            serve_points_total = winner_return_points_faced,
            serve_points_won = loser_first_serves_won + loser_second_serves_won
        ) %>%
        select(
            player = loser,
            tournament, tournament_date, court_surface, round_description,
            serve_points_total, serve_points_won,
            return_points_total = loser_return_points_faced,
            return_points_won = loser_return_points_won
        )

    # Append and filter out nas
    player_set = winner %>% union_all(loser)
    player_set = 
        player_set[complete.cases(player_set),] %>%
        mutate(tournament_date = tournament_date %>% dmy())
    
    
    # Perform filters and calcs
    if (is.null(tournament_name)) {
        
        # Filter years_before years back from today
        player_set_filtered = 
            player_set %>%
            filter(tournament_date %>% between(today()-years(years_before), today() - days(1)))
        
    } else {
        
        # Getting the tournament date
        this_tournament_date = player_set %>% filter(tournament == tournament_name, year(tournament_date) == year) %>% head(1) %>% pull(tournament_date)
        
        # Filter
        player_set_filtered = 
            player_set %>%
            filter(tournament_date %>% between(this_tournament_date-years(years_before), this_tournament_date - days(1)))
        
    }
        
    # Performn Calculations
    player_set_filtered %>%
        select(-(tournament:round_description)) %>%
        filter() %>%
        group_by(player) %>%
        summarise_all(sum, na.rm = TRUE) %>%
        mutate(
            serve_win_rate = serve_points_won / serve_points_total,
            return_win_rate = return_points_won / return_points_total,
            total_points_sample = serve_points_total + return_points_total
        ) %>%
        select(player, total_points_sample, serve_win_rate, return_win_rate) %>%
        arrange(desc(total_points_sample))
     
}

# Calculate logloss for 2018 Aus Open -----------------------------------------------------------

# We'll just filter on matches for players in the year before the open, hopefully giving a better indication of their point win percentages
pre_2018_aus_open_win_rates = 
    calculate_player_winrates(
        rawdf = mens, 
        tournament_name = "Australian Open, Melbourne", 
        year = 2018, 
        years_before = 1
    )

# Prediction Set
prediction_set_2018_aus_open = 
    mens %>%
    filter(
        tournament == "Australian Open, Melbourne", 
        tournament_date == "15-Jan-18", 
        round_description != "Qualifying"
    ) %>%
    select(player_1 = winner, player_2 = loser) %>%
    mutate(win_flag = 1)


# Apply predictions in parallel
plan(multiprocess)
simulated_predictions = 
    prediction_set_2018_aus_open %>%
    mutate(
        player_1_win_prob = future_pmap_dbl(
            .l = list(player_1, player_2),
            .f = function(player_1, player_2) {
                simulate_matchup(pre_2018_aus_open_win_rates, player_1, player_2, number_of_sims = 500)
            }
        )
    )

# Calculate log loss
LogLoss(
    y_pred = simulated_predictions$player_1_win_prob, 
    y_true = simulated_predictions$win_flag
)

# 0.577 which is not too bad

# Simluate all matchups for 2019 Aus Open -----------------------------------------------------------

# Getting womens data
womens = read_csv("WTA_matches_Jan_10.csv", na = ".")
womens = womens %>% clean_names()

# Next we'll use the dummy files to make predictions for all possible matchups
women_file = read_csv("women_dummy_submission_file.csv")
men_file = read_csv("men_dummy_submission_file.csv")

# Given how long a simulation takes we'll just run 10 sims each but if you were doing this really you'd want to run 1000 or more and optimise your code a little

# ++++++
# Womens
# ++++++

# Get women's winrates data
womens_winrates = 
    calculate_player_winrates(
        rawdf = womens, 
        years_before = 1
    )

# Simulate matchups
womens_predictions=
    women_file %>%
    mutate(
        player_1_win_prob = future_pmap_dbl(
            .l = list(player_1, player_2),
            .f = function(player_1, player_2) {
                simulate_matchup(womens_winrates, player_1, player_2, number_of_sims = 10)
            }
        )
    )

# ++++++
# Mens
# ++++++

# Get men's winrates data
mens_winrates = 
    calculate_player_winrates(
        rawdf = mens, 
        years_before = 1
    )

# Simulate matchups
mens_predictions=
    men_file %>%
    mutate(
        player_1_win_prob = future_pmap_dbl(
            .l = list(player_1, player_2),
            .f = function(player_1, player_2) {
                simulate_matchup(mens_winrates, player_1, player_2, number_of_sims = 10)
            }
        )
    )