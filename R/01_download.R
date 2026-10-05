# 01_download.R
# Download the ONS detailed time series (mid-2011 to mid-2025) and an
# LAD23 -> RGN23 lookup into data/raw/. Neither file is committed.

raw_dir <- file.path("data", "raw")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)
options(timeout = 1200)

# 1. ONS population estimates and components of change, detailed time series
mye_url <- paste0(
  "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/",
  "populationandmigration/populationestimates/datasets/",
  "estimatesofthepopulationforenglandandwales/mid2011tomid2025detailedtimeseries/",
  "myebtablesenglandwales20112025.xlsx"
)
mye_file <- file.path(raw_dir, "myebtablesenglandwales20112025.xlsx")
if (!file.exists(mye_file)) {
  message("Downloading ", mye_url)
  download.file(mye_url, mye_file, mode = "wb")
} else {
  message("Already present: ", mye_file)
}

# 2. ONS Open Geography Portal: LAD (Dec 2023) to RGN (Dec 2023) lookup, England.
#    Wales has no ONS regions; Welsh LAs (codes starting W) are assigned to
#    "Wales" in 02_tidy.R.
lookup_url <- paste0(
  "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/",
  "LAD23_RGN23_EN_LU/FeatureServer/0/query?where=1%3D1&outFields=LAD23CD,LAD23NM,",
  "RGN23CD,RGN23NM&returnGeometry=false&resultRecordCount=2000&f=json"
)
lookup_file <- file.path(raw_dir, "lad23_rgn23_en_lookup.csv")
if (!file.exists(lookup_file)) {
  message("Downloading LAD23 -> RGN23 lookup")
  js <- jsonlite::fromJSON(lookup_url)
  lk <- js$features$attributes
  stopifnot(nrow(lk) == 296)
  write.csv(lk, lookup_file, row.names = FALSE)
} else {
  message("Already present: ", lookup_file)
}

message("Download date: ", Sys.Date())
