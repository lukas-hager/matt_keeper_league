rm(list = ls())

gc()
gc()

library(data.table)
library(janitor)
library(xgboost)
library(openxlsx)
library(tidyverse)

# import the rosters

league_id <- '650808198130929664'

all_matchups <- bind_rows(
  lapply(c(1:11), function(week_val){
    httr::GET(str_interp('https://api.sleeper.app/v1/league/${league_id}/matchups/${week_val}')) %>% 
      httr::content(as = 'text') %>% 
      jsonlite::fromJSON() %>% 
      select(starters_points, starters) %>% 
      unnest(c(starters, starters_points)) %>% 
      mutate(week = week_val)
  })
)

players <- httr::GET(str_interp('https://api.sleeper.app/v1/players/nfl')) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  bind_rows(., .id = 'player_id_val')

matchups_positions <- all_matchups %>% 
  left_join(players %>% 
              select(player_id_val, fantasy_positions),
            by = c('starters' = 'player_id_val')) %>% 
  mutate(fantasy_positions = ifelse(fantasy_positions == 'LEO', 
                                    'LB', 
                                    fantasy_positions)) %>% 
  group_by(fantasy_positions) %>% 
  summarise(n = n(),
            min = min(starters_points),
            median = median(starters_points),
            mean = mean(starters_points),
            max = max(starters_points)) %>% 
  ungroup()

matchups_positions_unique <- all_matchups %>% 
  left_join(players %>% 
              select(player_id_val, fantasy_positions),
            by = c('starters' = 'player_id_val')) %>% 
  mutate(fantasy_positions = ifelse(fantasy_positions == 'LEO', 
                                    'LB', 
                                    fantasy_positions)) %>% 
  group_by(starters) %>% 
  mutate(is_dl_and_lb = sum(fantasy_positions == 'LB') > 0 & 
           sum(fantasy_positions == 'DL') > 0) %>% 
  ungroup() %>% 
  filter(is_dl_and_lb == FALSE | fantasy_positions == 'DL') %>% 
  group_by(fantasy_positions) %>% 
  summarise(n = n(),
            min = min(starters_points),
            median = median(starters_points),
            mean = mean(starters_points),
            max = max(starters_points)) %>% 
  ungroup()
