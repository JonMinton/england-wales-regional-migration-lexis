# 02_tidy.R
# Read sheet MYEB2 (LA x sex x single year of age, population and components
# of change, 2011-2025), attach regions, aggregate to region level and write a
# long tidy table to data/tidy/regional_components_2011_2025.csv.

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})

mye_file    <- file.path("data", "raw", "myebtablesenglandwales20112025.xlsx")
lookup_file <- file.path("data", "raw", "lad23_rgn23_en_lookup.csv")
out_dir     <- file.path("data", "tidy")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

region_levels <- c(
  "North East", "North West", "Yorkshire and The Humber", "East Midlands",
  "West Midlands", "East of England", "London", "South East", "South West",
  "Wales"
)

# Row 1 is a title; row 2 holds the column names.
raw <- read_excel(mye_file, sheet = "MYEB2", skip = 1)
message("MYEB2: ", nrow(raw), " rows, ", ncol(raw), " columns")
stopifnot(nrow(raw) == 57876)

lookup <- read_csv(lookup_file, show_col_types = FALSE) |>
  select(ladcode23 = LAD23CD, region = RGN23NM)

la_long <- raw |>
  pivot_longer(
    -c(ladcode23, laname23, country, sex, age),
    names_to = c("component", "year"),
    names_pattern = "^(.*)_(\\d{4})$",
    values_to = "value"
  ) |>
  mutate(year = as.integer(year), age = as.integer(age))

las <- distinct(raw, ladcode23, laname23, country) |>
  left_join(lookup, by = "ladcode23") |>
  mutate(region = if_else(country == "W", "Wales", region))
unmatched <- filter(las, is.na(region))
if (nrow(unmatched) > 0) {
  print(unmatched)
  stop("Some local authorities have no region")
}
message(nrow(las), " local authorities; ", n_distinct(las$region), " regions")

regional <- la_long |>
  left_join(select(las, ladcode23, region), by = "ladcode23") |>
  group_by(region, year, age, sex, component) |>
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = component, values_from = value) |>
  mutate(
    sex = toupper(sex),
    region = factor(region, levels = region_levels)
  ) |>
  arrange(region, sex, year, age) |>
  select(region, year, age, sex, population, births, deaths,
         any_of(c("internal_in", "internal_out", "internal_net",
                  "international_in", "international_out", "international_net",
                  "special_change", "other_change", "other_adjust", "unattrib")),
         everything())

# Sanity checks: regional totals equal the LA totals.
stopifnot(
  isTRUE(all.equal(
    sum(regional$population, na.rm = TRUE),
    sum(la_long$value[la_long$component == "population"], na.rm = TRUE)
  ))
)

out_file <- file.path(out_dir, "regional_components_2011_2025.csv")
write_csv(regional, out_file)
message("Wrote ", out_file, " (", nrow(regional), " rows, ",
        round(file.size(out_file) / 1e6, 1), " MB)")
