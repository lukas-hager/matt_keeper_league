rm(list = ls())
gc()
gc()

library(httr)
library(jsonlite)
library(tidyverse)

league_id <- '650808198130929664'
draft_id <- '650808198130929665'

picks <- httr::GET(str_interp('https://api.sleeper.app/v1/draft/${draft_id}/picks')) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() 

users <- httr::GET(str_interp('https://api.sleeper.app/v1/league/${league_id}/users')) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON()

teams <- httr::GET(str_interp('https://api.sleeper.app/v1/league/${league_id}/rosters')) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() 

players <- httr::GET(str_interp('https://api.sleeper.app/v1/players/nfl')) %>% 
  httr::content(as = 'text') %>% 
  jsonlite::fromJSON() %>% 
  bind_rows(., .id = 'player_id_val')

keeper_vals <- teams %>% 
  select(roster_id, owner_id, players) %>% 
  unnest(players) %>% 
  bind_rows(teams %>% 
              select(roster_id, owner_id, reserve) %>% 
              unnest(reserve) %>% 
              rename(players = reserve)) %>% 
  left_join(picks %>% 
              jsonlite::flatten() %>% 
              select(round, player_id),
            by = c('players' = 'player_id')) %>% 
  left_join(users %>% 
              select(user_id, display_name),
            by = c('owner_id' = 'user_id')) %>% 
  left_join(players %>% 
              select(player_id_val, full_name),
            by = c('players' = 'player_id_val')) %>% 
  distinct() %>% 
  mutate(keeper_val = ifelse(!is.na(round), round - 1, 26))

write_csv(keeper_vals,
          '~/Downloads/keeper_vals.csv')
