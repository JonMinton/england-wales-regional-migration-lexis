# England and Wales regional migration on Lexis surfaces, 2011–2025

How migration shapes the age structure of the English regions and Wales, using the ONS mid-year population estimates and components of change, mid-2011 to mid-2025.

This is an update of [JonMinton/uk_migrant_demography](https://github.com/JonMinton/uk_migrant_demography) (2015–17). That repository used the ONS "Components of Change" tables (MYEB1–MYEB3) for 2002–2013, aggregated local authorities (LAs) to regions, and drew trellis plots and shaded contour plots on Lexis surfaces (year across, age up) of population and of internal and international migration flows. This repository does the same with the current ONS detailed time series, and adds two summaries aimed at one question: **does London age?** As an aggregate, London takes in young adults and loses children, their parents and people nearing retirement, so its age structure stays much younger than it would otherwise be.

## Figures

| File | What it shows |
|---|---|
| `figures/01a_lexis_population_share.png` | Lexis surface of age structure: persons at each age per 1,000 of the region's population, by region, 2011–2025 |
| `figures/01b_lexis_population_count.png` | The same surface as counts (thousands, shared scale) |
| `figures/01c_lexis_net_internal_rate.png` | Net internal migration per 1,000 of the age-specific population, 2012–2025 |
| `figures/01d_lexis_net_international_rate.png` | Net international migration per 1,000, 2012–2025 |
| `figures/01e_lexis_net_total_rate.png` | Net migration (internal + international) per 1,000, 2012–2025 |
| `figures/02_median_age_by_region.png` | Median age by region, 2011–2025, London highlighted |
| `figures/02b_median_age_vs_no_migration.png` | Observed median age against a no-migration counterfactual |
| `figures/03a_net_migration_age_profile.png` | Net migration per 1,000 by single year of age: year to mid-2025 and the 2012–2025 average |
| `figures/03b_net_migration_internal_vs_international.png` | The 2012–2025 average age profile split into internal and international |

Rates are diverging (ColorBrewer PuOr: orange = net loss, purple = net gain, centred on zero; colour-blind safe) and capped at the 98th percentile of absolute values so the student-age extremes don't wash out everything else. Population uses a sequential palette (viridis "mako").

## First findings

All figures are for persons (both sexes) and refer to the 12 months to mid-year.

1. **London is the youngest region, and the gap is not closing.** London's median age was 33.8 in 2011 and 36.2 in 2025 (+2.3 years). Other regions rose by between 0.2 (North West, 40.0 to 40.3) and 1.7 years (Wales, 41.5 to 43.2). So London's median age is not stationary: over 2011–2025 it rose by more than any other region's. Its mean age rose 2.0 years (36.1 to 38.1), similar to the other regions (+1.2 to +2.1).
2. **Without migration, London would have aged much faster.** If each region's mid-2011 population is rolled forward with observed births and death ratios but no migration, London's 2025 median age would be 40.7, not 36.2: migration has left it **4.5 years younger**. Elsewhere the effect is 0.7 to 1.7 years; in Wales it is nil (43.2 either way). This is the clearest form of the "London barely ages" point: it ages slowly *relative to what its own cohorts would do*, though not in absolute terms.
3. **London's age profile of net migration, average 2012–2025 (per 1,000 at that age):** net gains at ages 18–21 (+35) and 22–29 (+53, peaking at +123 at age 23); net losses at ages 0–10 (−17), 30–44 (−12), 45–59 (−10), 60–74 (−13) and 75–89 (−9). Internal migration is negative at almost every age outside 22–29 (−25 per 1,000 at ages 0–10, −25 at 30–44, −14 at 60–74); international migration is positive at almost every age and largest at 18–21 (+58).
4. **In the year to mid-2025 the pattern sharpened** as international inflows fell: London gained +47 per 1,000 at ages 22–29 and lost −32 per 1,000 at ages 30–44 (about 70,000 people net, of whom 65,000 internal) and −23 at ages 0–10.
5. **London loses people internally every year**, from −50,000 in 2012 to a peak of −186,000 in 2021 (the pandemic year) and −132,000 in 2025, and gains them internationally (+38,000 in 2020 up to +235,000 in 2023, then +52,000 in 2025). Other regions show the mirror image of London's internal pattern in milder form: university regions (North East, Yorkshire, East Midlands) gain at 18–19 and lose at 21–24, and the East and South East gain children and adults in their 30s, the age group London loses.

## Data

- **Population and components of change:** ONS, *Estimates of the population for England and Wales*, edition "Mid-2011 to mid-2025 detailed time series", file `myebtablesenglandwales20112025.xlsx`, sheet `MYEB2` (LA by sex by single year of age 0–90+, population at mid-2011 to mid-2025 and births, deaths, internal in/out/net, international in/out/net, special-population change, unattributable change and other adjustments for the 12 months to each mid-year 2012–2025). Released 29 July 2026.
- **LA to region lookup:** ONS Open Geography Portal, *LAD (December 2023) to Region (December 2023) Lookup in England* (`LAD23_RGN23_EN_LU`, 296 English LAs). The 22 Welsh LAs (codes `W...`) are grouped as "Wales".
- Exact URLs and download dates: [`data/raw/SOURCES.md`](data/raw/SOURCES.md).
- **Licence:** both sources are Crown copyright, used under the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/). Contains ONS data © Crown copyright and database right 2026. The code in this repository is MIT licensed.

Derived data committed in `data/tidy/`:

- `regional_components_2011_2025.csv` (1.8 MB): region × year × age × sex, all components.
- `median_mean_age_by_region.csv`, `median_age_observed_vs_no_migration.csv`, `net_migration_age_profile.csv`: the numbers behind figures 2, 2b and 3.

## How to run

Requires R (≥ 4.1) with `tidyverse`, `readxl`, `scales` and `jsonlite`. From the repository root:

```sh
Rscript run_all.R
```

This runs `R/01_download.R` (downloads the 49 MB ONS workbook and the lookup into `data/raw/`, which is gitignored), `R/02_tidy.R` (reads `MYEB2`, joins regions, aggregates and writes the tidy CSV, checking that regional totals match LA totals) and `R/03_figures.R` (figures and summary tables). It takes a minute or two, mostly reading the workbook.

## Methods and caveats

- **Not comparable with the original 2002–2013 analysis.** This series is consistent with Census 2021: ONS rebased the mid-2012 to mid-2020 estimates to bridge Census 2011 and Census 2021. Mid-2022 to mid-2024 have been revised for updated international migration estimates. The original repository used the pre-2021 Census-based series with different methods, especially for international and internal migration. Compare the shapes of the patterns, not levels across the two series.
- **Regional internal migration is LA-to-LA moves summed to regions**, as in the original. "Internal in" to London includes moves from one London borough to another, and the same moves also appear as "internal out". These cancel in the net figures, which is why the figures use net rates, but the gross in and out flows are inflated by within-region moves. Internal migration also includes moves to and from Scotland and Northern Ireland.
- **Age and timing:** components are for the 12 months to mid-year *y*, by age at mid-year *y*. Rates are per 1,000 of the population at that age at mid-year *y* (end of period). The demographic accounting identity (population at age *a*, year *y* = population at age *a*−1, year *y*−1 + births − deaths + net internal + net international + special change + unattributable + adjustments) holds exactly for 2012–2021; for 2022–2025 the `unattrib` column is not populated.
- **Ages 90+ are an open-ended group** and are left out of the Lexis surfaces and age profiles. Rates at the oldest single ages rest on small numbers and are noisy, especially in the smaller regions. ONS notes that the unrounded estimates should not be taken as accurate to the level of detail shown.
- **Median age** is interpolated within single years of age (age *a* covers [*a*, *a*+1)).
- **The no-migration counterfactual** holds births at observed levels. Without migration, London would have fewer women of childbearing age and so fewer births, which would make the counterfactual population older still; the 4.5-year gap is therefore, if anything, an understatement. Death ratios are the observed deaths at age *a* over the observed population at age *a*−1 a year earlier.
- **Student ages:** the sharp bands at 18–23 in the Lexis surfaces are students arriving and graduates leaving (students are counted at term-time addresses).

## Possible next steps

- The GLA's modelled population backseries (origin–destination flows, 2001–2024) could separate inter-regional from intra-regional moves, so London's internal flows to and from the rest of the UK can be shown without the borough-to-borough churn.
- Sex-specific surfaces (the tidy data already carries sex), and the Scottish (NRS) and Northern Irish (NISRA) equivalents to complete a UK picture, as the original README planned.
- Linking to the 2001–2011 detailed time series (`myebtablesewsn20012011.xlsx`, same ONS page) for a longer, if discontinuous, view.
