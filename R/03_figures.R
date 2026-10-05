# 03_figures.R
# Figures from data/tidy/regional_components_2011_2025.csv into figures/.

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

fig_dir <- "figures"
dir.create(fig_dir, showWarnings = FALSE)

region_levels <- c(
  "North East", "North West", "Yorkshire and The Humber", "East Midlands",
  "West Midlands", "East of England", "London", "South East", "South West",
  "Wales"
)
src_caption <- "Source: ONS mid-year estimates, detailed time series 2011–2025 (Census 2021-consistent). Ages 0–89 shown; 90+ omitted."

d <- read_csv("data/tidy/regional_components_2011_2025.csv",
              show_col_types = FALSE) |>
  mutate(region = factor(region, levels = region_levels))

# Persons (both sexes combined)
p <- d |>
  group_by(region, year, age) |>
  summarise(across(c(population, births, deaths, internal_in, internal_out,
                     internal_net, international_in, international_out,
                     international_net), \(x) sum(x)),
            .groups = "drop") |>
  group_by(region, year) |>
  mutate(pop_share = 1000 * population / sum(population)) |>
  ungroup() |>
  mutate(
    # Components are for the 12 months to mid-year `year`, by age at mid-year
    # `year`. Rates use the mid-year population at the same age as denominator.
    net_total = internal_net + international_net,
    r_internal = 1000 * internal_net / population,
    r_international = 1000 * international_net / population,
    r_total = 1000 * net_total / population
  )

theme_lexis <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 10.5, colour = "grey25"),
    plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    strip.text = element_text(face = "bold", size = 10),
    panel.grid = element_blank(),
    legend.position = "bottom",
    legend.key.width = unit(2.2, "cm"),
    legend.key.height = unit(0.35, "cm"),
    plot.background = element_rect(fill = "white", colour = NA)
  )

lexis_base <- function(data, fill_var) {
  ggplot(data |> filter(age < 90), aes(x = year, y = age, fill = {{ fill_var }})) +
    geom_raster() +
    facet_wrap(~region, nrow = 2) +
    scale_x_continuous(breaks = c(2012, 2016, 2020, 2024), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq(0, 80, 20), expand = c(0, 0)) +
    labs(x = "Year (mid-year)", y = "Age (single years)", caption = src_caption) +
    theme_lexis
}

save_fig <- function(plot, name, width = 13, height = 7.5) {
  ggsave(file.path(fig_dir, name), plot, width = width, height = height,
         dpi = 150, bg = "white")
  message("Saved figures/", name)
}

# A symmetric limit for the diverging scale: 98th percentile of |rate| at ages
# 0-89, rounded, so a handful of extreme student-age cells do not wash out the
# rest. Values beyond it are drawn at the end colour (squished).
sym_limit <- function(x, step = 5) {
  ceiling(quantile(abs(x), 0.98, na.rm = TRUE) / step) * step
}
div_scale <- function(lim, name) {
  scale_fill_distiller(
    palette = "PuOr", direction = 1, limits = c(-lim, lim), oob = squish,
    name = name, breaks = pretty(c(-lim, lim), 5)
  )
}

# ---- 1a. Population structure (share of region total) ---------------------
f1a <- lexis_base(p, pop_share) +
  scale_fill_viridis_c(option = "mako", direction = -1,
                       name = "Persons at each age per 1,000 of the region's population") +
  labs(title = "Population age structure by region, England and Wales, 2011–2025",
       subtitle = "Lexis surface: year across, age up. London's mass sits at ages ~25–45 throughout; other regions show the 1946-47 and 1960s birth cohorts ageing diagonally.")
save_fig(f1a, "01a_lexis_population_share.png")

f1a2 <- lexis_base(p, population / 1000) +
  scale_fill_viridis_c(option = "mako", direction = -1,
                       name = "Population at each single year of age (thousands)") +
  labs(title = "Population by single year of age, region and year, England and Wales, 2011–2025",
       subtitle = "Lexis surface of counts (shared scale, so larger regions are darker overall).")
save_fig(f1a2, "01b_lexis_population_count.png")

# ---- 1b/1c. Net migration rates --------------------------------------------
pr <- filter(p, year >= 2012)
lim_int <- sym_limit(pr$r_internal[pr$age < 90])
f1b <- lexis_base(pr, r_internal) +
  div_scale(lim_int, "Net internal migration per 1,000 population at that age (orange = net loss, purple = net gain)") +
  labs(title = "Net internal migration rate by age, region and year, 2012–2025",
       subtitle = paste0("Moves between local authorities (within and between regions, plus to/from Scotland and NI), per 1,000 of the age-specific population. ",
                         "Colours capped at ±", lim_int, "."))
save_fig(f1b, "01c_lexis_net_internal_rate.png")

lim_intl <- sym_limit(pr$r_international[pr$age < 90])
f1c <- lexis_base(pr, r_international) +
  div_scale(lim_intl, "Net international migration per 1,000 population at that age (orange = net loss, purple = net gain)") +
  labs(title = "Net international migration rate by age, region and year, 2012–2025",
       subtitle = paste0("Immigration minus emigration per 1,000 of the age-specific population. Colours capped at ±", lim_intl,
                         ". Note the 2022–2024 surge."))
save_fig(f1c, "01d_lexis_net_international_rate.png")

lim_tot <- sym_limit(pr$r_total[pr$age < 90])
f1d <- lexis_base(pr, r_total) +
  div_scale(lim_tot, "Net migration (internal + international) per 1,000 population at that age") +
  labs(title = "Net migration rate (internal + international) by age, region and year, 2012–2025",
       subtitle = paste0("Colours capped at ±", lim_tot, "."))
save_fig(f1d, "01e_lexis_net_total_rate.png")

# ---- 2. Median and mean age over time ---------------------------------------
median_age <- function(age, pop) {
  # Single years of age; age a covers [a, a+1). Linear interpolation within
  # the year of age where the cumulative share crosses 50%. 90 = 90+.
  o <- order(age); age <- age[o]; pop <- pop[o]
  cs <- cumsum(pop) / sum(pop)
  i <- which(cs >= 0.5)[1]
  prev <- if (i == 1) 0 else cs[i - 1]
  age[i] + (0.5 - prev) / (cs[i] - prev)
}
ages <- p |>
  group_by(region, year) |>
  summarise(median_age = median_age(age, population),
            mean_age = sum((age + 0.5) * population) / sum(population),
            .groups = "drop")
write_csv(mutate(ages, across(c(median_age, mean_age), \(x) round(x, 2))),
          file.path("data", "tidy", "median_mean_age_by_region.csv"))

lab_end <- filter(ages, year == max(year))
f2 <- ggplot(ages, aes(year, median_age, group = region)) +
  geom_line(data = filter(ages, region != "London"), colour = "grey60", linewidth = 0.7) +
  geom_line(data = filter(ages, region == "London"), colour = "#B2182B", linewidth = 1.4) +
  geom_point(data = filter(ages, region == "London"), colour = "#B2182B", size = 1.8) +
  geom_text(data = lab_end, aes(label = sprintf("%s  %.1f", region, median_age),
                                colour = region == "London",
                                fontface = ifelse(region == "London", "bold", "plain")),
            hjust = 0, nudge_x = 0.25, size = 3.3, check_overlap = FALSE) +
  scale_colour_manual(values = c(`TRUE` = "#B2182B", `FALSE` = "grey30"), guide = "none") +
  scale_x_continuous(breaks = seq(2011, 2025, 2), expand = expansion(add = c(0.3, 5.5))) +
  scale_y_continuous(breaks = seq(30, 50, 2)) +
  labs(title = "Median age by region, 2011–2025: London stays youngest but still ages",
       subtitle = "Median age of the usually resident population (persons). London in red; other regions and Wales in grey, labelled with their 2025 value.",
       x = NULL, y = "Median age (years)",
       caption = "Source: ONS mid-year estimates, detailed time series 2011–2025. Median interpolated within single years of age.") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 15),
        plot.subtitle = element_text(size = 10.5, colour = "grey25"),
        plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
        plot.title.position = "plot", plot.caption.position = "plot",
        panel.grid.minor = element_blank(),
        plot.background = element_rect(fill = "white", colour = NA))
# Spread end labels that would collide.
lab_end <- lab_end |> arrange(median_age) |>
  mutate(y_lab = median_age)
for (k in seq_len(nrow(lab_end))[-1]) {
  lab_end$y_lab[k] <- max(lab_end$y_lab[k], lab_end$y_lab[k - 1] + 0.42)
}
f2$layers[[4]]$data <- lab_end
f2$layers[[4]]$mapping$y <- quote(y_lab)
save_fig(f2, "02_median_age_by_region.png", width = 11, height = 7)

# ---- 2b. No-migration counterfactual ---------------------------------------
# Start from each region's observed mid-2011 population and roll it forward
# with observed births and observed age-specific death ratios, but with all
# migration (internal, international, special and unattributed change) set to
# zero. Death ratio q[a, y] = deaths at age a in the year to mid-y divided by
# the population aged a-1 at mid-(y-1) (for 90+: aged 89 and 90+). Births are
# held at observed levels: a simplification, since without migration there
# would be fewer women of childbearing age in London.
no_mig <- function(df) {
  df <- arrange(df, year, age)
  yrs <- sort(unique(df$year))
  P  <- matrix(df$population, nrow = 91)  # ages 0..90 x years
  D  <- matrix(df$deaths, nrow = 91)
  B  <- tapply(df$births, df$year, sum)
  cf <- P
  for (j in 2:length(yrs)) {
    prev_obs <- P[, j - 1]
    q <- numeric(91)
    q[1] <- D[1, j] / B[j]
    q[2:90] <- D[2:90, j] / prev_obs[1:89]
    q[91] <- D[91, j] / (prev_obs[90] + prev_obs[91])
    q <- pmin(pmax(q, 0), 1)
    cf[1, j] <- B[j] * (1 - q[1])
    cf[2:90, j] <- cf[1:89, j - 1] * (1 - q[2:90])
    cf[91, j] <- (cf[90, j - 1] + cf[91, j - 1]) * (1 - q[91])
  }
  tibble(year = rep(yrs, each = 91), age = rep(0:90, length(yrs)),
         population = as.vector(cf))
}
cf_ages <- p |>
  group_by(region) |>
  group_modify(\(df, key) {
    no_mig(df) |> group_by(year) |>
      summarise(median_age = median_age(age, population), .groups = "drop")
  }) |>
  ungroup() |>
  mutate(scenario = "No migration since mid-2011")
cmp <- bind_rows(mutate(ages, scenario = "Observed") |> select(region, year, median_age, scenario),
                 cf_ages) |>
  mutate(scenario = factor(scenario, levels = c("Observed", "No migration since mid-2011")))
write_csv(mutate(cmp, median_age = round(median_age, 2)),
          file.path("data", "tidy", "median_age_observed_vs_no_migration.csv"))

gap <- cmp |> filter(year == max(year)) |>
  pivot_wider(names_from = scenario, values_from = median_age) |>
  mutate(gap = `No migration since mid-2011` - Observed)
f2b <- ggplot(cmp, aes(year, median_age, colour = scenario, linetype = scenario)) +
  geom_line(linewidth = 0.9) +
  geom_text(data = gap, inherit.aes = FALSE,
            aes(x = 2011.3, y = 49, label = sprintf("2025 gap: %.1f yrs", round(gap, 1) + 0)),
            hjust = 0, size = 3.2, colour = "grey20") +
  facet_wrap(~region, nrow = 2) +
  scale_colour_manual(values = c("Observed" = "#5E3C99",
                                 "No migration since mid-2011" = "#E66101"), name = NULL) +
  scale_linetype_manual(values = c("Observed" = "solid",
                                   "No migration since mid-2011" = "22"), name = NULL) +
  scale_x_continuous(breaks = c(2012, 2018, 2024)) +
  scale_y_continuous(breaks = seq(30, 50, 4)) +
  labs(title = "Median age, observed vs. a no-migration counterfactual, 2011–2025",
       subtitle = "Counterfactual: each region's mid-2011 population rolled forward with observed births and death ratios, but no migration in or out.\nThe gap is how much younger (positive) or older (negative) migration has left each region's population by 2025.",
       x = NULL, y = "Median age (years)",
       caption = "Source: ONS mid-year estimates, detailed time series 2011–2025. Counterfactual holds births at observed levels; see README.") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 15),
        plot.subtitle = element_text(size = 10.5, colour = "grey25"),
        plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
        plot.title.position = "plot", plot.caption.position = "plot",
        strip.text = element_text(face = "bold", size = 10),
        panel.grid.minor = element_blank(), legend.position = "top",
        legend.justification = "left",
        plot.background = element_rect(fill = "white", colour = NA))
save_fig(f2b, "02b_median_age_vs_no_migration.png", width = 13, height = 7)
print(arrange(gap, desc(gap)))

# ---- 3. Age profile of net migration ---------------------------------------
recent <- max(pr$year)
prof <- bind_rows(
  pr |> filter(year == recent) |>
    transmute(region, age, period = paste0("12 months to mid-", recent),
              internal = r_internal, international = r_international, total = r_total),
  pr |> group_by(region, age) |>
    summarise(internal = 1000 * sum(internal_net) / sum(population),
              international = 1000 * sum(international_net) / sum(population),
              total = 1000 * sum(net_total) / sum(population), .groups = "drop") |>
    mutate(period = "Average, 2012–2025")
) |> filter(age < 90)
write_csv(mutate(prof, across(c(internal, international, total), \(x) round(x, 2))),
          file.path("data", "tidy", "net_migration_age_profile.csv"))

period_cols <- c("#B35806", "#542788")
names(period_cols) <- c(paste0("12 months to mid-", recent), "Average, 2012–2025")

f3 <- ggplot(prof, aes(age, total, colour = period)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_vline(xintercept = c(18, 30, 65), colour = "grey85", linewidth = 0.3) +
  geom_line(linewidth = 0.8) +
  facet_wrap(~region, nrow = 2) +
  scale_colour_manual(values = period_cols, name = NULL) +
  coord_cartesian(ylim = c(-60, 120)) +
  scale_x_continuous(breaks = seq(0, 80, 20)) +
  labs(title = "Net migration (internal + international) by single year of age",
       subtitle = "Net moves per 1,000 population at that age. London gains people in their 20s and loses children and their parents (30s–40s) and people near retirement.\nVertical guides at ages 18, 30 and 65. Y-axis clipped to −60 to +120.",
       x = "Age at mid-year", y = "Net migration per 1,000", caption = src_caption) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 15),
        plot.subtitle = element_text(size = 10.5, colour = "grey25"),
        plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
        plot.title.position = "plot", plot.caption.position = "plot",
        strip.text = element_text(face = "bold", size = 10),
        panel.grid.minor = element_blank(), legend.position = "top",
        legend.justification = "left",
        plot.background = element_rect(fill = "white", colour = NA))
save_fig(f3, "03a_net_migration_age_profile.png", width = 13, height = 7.5)

comp <- prof |> filter(period == "Average, 2012–2025") |>
  pivot_longer(c(internal, international), names_to = "type", values_to = "rate") |>
  mutate(type = recode(type, internal = "Internal (within UK)",
                       international = "International"))
f3b <- ggplot(comp, aes(age, rate, colour = type)) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  facet_wrap(~region, nrow = 2) +
  scale_colour_manual(values = c("Internal (within UK)" = "#E66101",
                                 "International" = "#5E3C99"), name = NULL) +
  coord_cartesian(ylim = c(-60, 120)) +
  scale_x_continuous(breaks = seq(0, 80, 20)) +
  labs(title = "Internal and international net migration by age, average 2012–2025",
       subtitle = "Net moves per 1,000 population at that age, pooled over 2012–2025. London's losses at most ages are internal; its gains are international and, at ~20–30, internal.",
       x = "Age at mid-year", y = "Net migration per 1,000", caption = src_caption) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 15),
        plot.subtitle = element_text(size = 10.5, colour = "grey25"),
        plot.caption = element_text(size = 8.5, colour = "grey35", hjust = 0),
        plot.title.position = "plot", plot.caption.position = "plot",
        strip.text = element_text(face = "bold", size = 10),
        panel.grid.minor = element_blank(), legend.position = "top",
        legend.justification = "left",
        plot.background = element_rect(fill = "white", colour = NA))
save_fig(f3b, "03b_net_migration_internal_vs_international.png", width = 13, height = 7.5)

# ---- Console summary used for the README findings --------------------------
ages |> filter(year %in% c(2011, 2025)) |>
  pivot_wider(id_cols = region, names_from = year, values_from = median_age,
              names_prefix = "median_") |>
  mutate(change = median_2025 - median_2011) |>
  arrange(change) |> print()
