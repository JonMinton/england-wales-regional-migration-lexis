# Raw data sources

Files in this folder are downloaded by `R/01_download.R` and are not committed.

| File | Source | Release | Downloaded |
|---|---|---|---|
| `myebtablesenglandwales20112025.xlsx` (48.8 MB) | ONS, *Estimates of the population for England and Wales*, edition "Mid-2011 to mid-2025 detailed time series". Dataset page: https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/estimatesofthepopulationforenglandandwales . File: https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/estimatesofthepopulationforenglandandwales/mid2011tomid2025detailedtimeseries/myebtablesenglandwales20112025.xlsx | 29 July 2026, 9:30am | 5 October 2026 |
| `lad23_rgn23_en_lookup.csv` (296 rows) | ONS Open Geography Portal, *Local Authority District to Region (December 2023) Lookup in England*, feature service `LAD23_RGN23_EN_LU`: https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LAD23_RGN23_EN_LU/FeatureServer/0 | December 2023 boundaries | 5 October 2026 |

Sheets used: `MYEB2` (population and components of change by LA, sex and single year of age 0 to 90+, 2011 to 2025; 57,876 rows). `MYEB1` (population only) and `MYEB3` (components by LA, all ages) are not used.

Both sources are Crown copyright, released under the Open Government Licence v3.0.
