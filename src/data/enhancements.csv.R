# ===== Load libraries ===== #
library(tidyverse)
library(here)

# ===== Read in data ===== #
enhancements <- read_csv(here("src", "data", "enhancements_raw.csv"), show_col_types = FALSE)

# ===== Process for mapping enhancement locations ===== #

# Filter to sites with geographic data and select columns
enhancements_map_pts <- enhancements |>
    filter(!is.na(enhancement_latitude_est),
            !is.na(enhancement_longitude_est)) |>
    select(site_name, enhancement_latitude_est, enhancement_longitude_est, 
            enhancement_type, enhancement_years)


# ===== Output as CSV ===== #
write_csv(enhancements_map_pts, stdout())
