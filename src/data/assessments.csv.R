# ===== Load libraries ===== #
library(tidyverse)
library(here)

# ===== Read in data ===== #
assessments <- read_csv(here("src", "data", "libertybay_assessment_counts_raw.csv"), show_col_types = FALSE)

# ===== Processing ===== #
# Filter to project areas
assessments <- assessments |>
  filter(location == "Legion Park",
         pop_type == "project")

# Add year column for grouping
assessments <- assessments |>
  mutate(year = lubridate::year(date))

# Calculate oly density (# live olys / total_sample_area = olys m ^-2)
assessments <- assessments |>
  mutate(live_oly_density_m2 = live_oly_count / total_sample_area_m2)

# Summarise to annual total counts
total_counts_ann <- assessments |>
  group_by(year, pop_type, location, site) |>
  summarise(total_oly_count = sum(live_oly_count, na.rm = TRUE))

# Summarise to annual average density
avg_ann_density <- assessments |>
  group_by(year, pop_type, location, site) |>
  summarise(density = mean(live_oly_density_m2, na.rm = TRUE))


# Trying again, with Sinclair
assessments_sinclair <- read_csv(here("src", "data", "sinclair_assessment_counts_raw.csv"), show_col_types = FALSE)

# ===== Processing ===== #
# Filter to project areas
assessments_sinclair <- assessments_sinclair |>
  filter(location == "Sinclair Inlet",
         pop_type == "project")

# Add year column for grouping
assessments_sinclair <- assessments_sinclair |>
  mutate(year = lubridate::year(date))

# Calculate oly density (# live olys / total_sample_area = olys m ^-2)
assessments_sinclair <- assessments_sinclair |>
  mutate(live_oly_density_m2 = live_oly_count / total_sample_area_m2)

# Summarise to annual total counts
total_counts_ann <- assessments_sinclair |>
  group_by(year, pop_type, location, site) |>
  summarise(total_oly_count = sum(live_oly_count, na.rm = TRUE))

# Summarise to annual average density
sinclair_avg_ann_density <- assessments_sinclair |>
  group_by(year, pop_type, location, site) |>
  summarise(density = mean(live_oly_density_m2, na.rm = TRUE))

# Join Legion Park and Sinclair together
annual_densities <- rbind(avg_ann_density, sinclair_avg_ann_density)  

# ===== Output as CSV ===== #
write_csv(annual_densities, stdout())

