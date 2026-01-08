# ===== Load libraries ===== #
library(tidyverse)
library(here)

# ===== Read in data ===== #
recruit_stations <- read_csv(here("oly-dashboard", "src", "data", "recruitment_station_info.csv"), show_col_types = FALSE)
recruit_index <- read_csv(here("oly-dashboard", "src", "data", "recruit_index.csv"), show_col_types = FALSE)

# ===== Data Processing ===== #

