# ===========================================================================
# Use of Microsoft365R package commands to access files directly from SP site.
# ===========================================================================

# --- Setup ---

# Install the Microsoft365R package from GitHub
# Uncomment and run, if first time.
# devtools::install_github("Azure/Microsoft365R")

# Load libraries
library(Microsoft365R)
library(readxl)

# --- Accessing a SP Site ---

# This is the command to access the contents of sharepoint site:
site <- get_sharepoint_site(
  site_url = "https://tetratechinc.sharepoint.com/teams/704-ENW.BIOS03195-01/"
)

# There are various asset types in SP. We want the drive contents.
# Get the drive contents of the site.

drv <- site$get_drive()

# Now list those items
drv$list_items()

# The items within a subfolder can be listed:
drv$list_items("003a Analysis and Reporting FY25-26")
drv$list_items("003a Analysis and Reporting FY25-26/EEM")
drv$list_items("003a Analysis and Reporting FY25-26/EEM/Analysis")
drv$list_items("003a Analysis and Reporting FY25-26/EEM/Analysis/Water")

# For convenience, create a path to a folder of interest (in this case, Water)
path_water <- "003a Analysis and Reporting FY25-26/EEM/Analysis/Water"

# Create the full path to the file of interest in the water folder.
# This is not strictly needed, just that the folders and filenames are so long,
# its best to create the path to a target file of interest separately and then
# use it to access the file.

path_file <- file.path(
  path_water,
  "Tbl 1, 2 - Surface Water Analytical Results + QAQC.xlsx"
)

# --- Getting a file ---

# .csv, .rds and RDATA files type can be read directly from the drive.
# Excel files (and all others) must be downloaded first to a local directory
# and then read in.

# for csv. .rds and .Rdata files:
# drv$load_dataframe("path/to/file.csv")
# drv$load_rds("path/to/object.rds")
# drv$load_rdata("path/to/workspace.RData")

# For excel, The file has to be retrieved first and stored in a local directory.
# We will create a temporary folder for this purpose. The file will be
# downloaded to the temp folder and then read in from there.
# The tmp folder shuld be added to the .gitignore so it does not get added to
# the repo.

if (!dir.exists("tmp")) {
  dir.create("tmp", recursive = TRUE)
  normalizePath("tmp", mustWork = TRUE)
}

# Then download to the local directory
drv$download_file(path_file, dest = "tmp/excel_file_tmp.xlsx", overwrite = TRUE)

# And finally, read in the file from the local directory, as you would
# normally do with read_excel.
# Just an example.
data <- read_excel("tmp/excel_file_tmp.xlsx", sheet = 1, skip = 4)


# --- Bare bones code to read in the file directly from SP ---
{
  site <- get_sharepoint_site(
    site_url = "https://tetratechinc.sharepoint.com/teams/704-ENW.BIOS03195-01/"
  )

  drv <- site$get_drive()

  if (!dir.exists("tmp")) {
    dir.create("tmp", recursive = TRUE)
  }

  drv$download_file(
    "003a Analysis and Reporting FY25-26/EEM/Analysis/Water/Tbl 1, 2 - Surface Water Analytical Results + QAQC.xlsx",
    dest = "tmp/excel_file_tmp.xlsx",
    overwrite = TRUE
  )

  data <- read_excel("tmp/excel_file_tmp.xlsx", sheet = 1, skip = 4)
}


# --- Compare with W drive ---
{
  w_fname <- "W:/Projects/VAN/69650/704-ENW.BIOS03195-01/Data/test/Tbl 1, 2 - Surface Water Analytical Results + QAQC.xlsx"

  data <- read_excel(w_fname, sheet = 1, skip = 4)
}
