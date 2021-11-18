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

matt_db <- picks %>% 
  jsonlite::flatten() %>% 
  select(round, pick_no, picked_by, metadata.first_name, metadata.last_name,
         player_id) %>% 
  left_join(users %>% 
              select(user_id, display_name),
            by = c('picked_by' = 'user_id'))

write_csv(matt_db,
          '~/Downloads/matt_db.csv')
