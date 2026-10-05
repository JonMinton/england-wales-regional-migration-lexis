# run_all.R: run the pipeline end to end from the repository root.
for (s in c("R/01_download.R", "R/02_tidy.R", "R/03_figures.R")) {
  message("\n=== ", s, " ===")
  source(s, echo = FALSE, local = new.env())
}
