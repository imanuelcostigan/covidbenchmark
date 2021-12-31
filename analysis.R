library(tidyverse)
library(janitor)

# Get core data
url <- "https://github.com/owid/covid-19-data/raw/master/public/data/owid-covid-data.csv"
owid <- read_csv(url)

# Get supplmental, auxilliary, hospitalisation data
hosp_url <- "https://github.com/owid/covid-19-data/raw/master/public/data/hospitalizations/covid-hospitalizations.csv"
hosp <- read_csv(hosp_url)
hosp <-
  hosp |>
  pivot_wider(
    id_cols = c("entity", "iso_code", "date"),
    names_from = indicator,
    values_from = value,
    names_repair = \(x) make_clean_names(x) |> paste0("_aux")
  ) |>
  rename(
    entity = entity_aux,
    iso_code = iso_code_aux,
    date = date_aux
  )

countries <- c("AUS", "NZL", "USA", "GBR", "CAN", "DEU", "SGP", "DNK", "ISR",
  "JPN", "KOR", "NLD", "NOR", "SWE")
start_date <- as.Date("2021-09-01")

# Explore core OWID data

owid |>
  filter(
    iso_code %in% countries,
    date >= start_date
  ) |>
  select(
    iso_code,
    continent,
    location,
    new_cases_smoothed_per_million,
    new_tests_smoothed_per_thousand,
    people_fully_vaccinated_per_hundred,
    hosp_patients_per_million,
    weekly_hosp_admissions_per_million,
    icu_patients_per_million,
    weekly_icu_admissions_per_million,
    new_deaths_smoothed_per_million,
  ) |>
  pivot_longer(
    cols = !c("iso_code", "continent", "location"),
  ) |>
  group_by(iso_code, name) |>
  summarise(n = n(), not_na = sum(!is.na(value))) |>
  pivot_wider(
    id_cols = name,
    names_from = iso_code,
    values_from = not_na
  )

# Explore aux hospitalisation data

hosp |>
  filter(
    iso_code %in% countries,
    date >= start_date
  ) |>
  pivot_longer(
    cols = !c("entity", "iso_code", "date")
  ) |>
  group_by(iso_code, name) |>
  summarise(n = n(), notna = sum(!is.na(value))) |>
  pivot_wider(
    id_cols = name,
    names_from = iso_code,
    values_from = notna
  )

# Join core with aux hospitalisatio data

owid_aug <-
  owid |>
  left_join(hosp, by = c("iso_code", "location" = "entity", "date")) |>
  filter(
    iso_code %in% countries,
    date >= start_date
  )
owid_aug |>
  select(iso_code, date, contains("icu")) |>
  filter(iso_code == "GBR")

# Looks like the aux data is already in the core data set. Ignore this going
# forward


owid_long_tbl <-
  owid |>
  filter(
    iso_code %in% countries,
    date >= start_date
  ) |>
  select(
    iso_code,
    location,
    date,
    # "Tests conducted per new confirmed case of COVID-19, given as a rolling
    #  7-day average (this is the inverse of positive_rate)"
    new_tests_smoothed_per_thousand,
    new_cases_smoothed_per_million,
    tests_per_case,
    hosp_patients_per_million, # stock, not flow.
    icu_patients_per_million,  # stock, not flow.
    new_deaths_smoothed_per_million
  ) |>
  pivot_longer(
    cols = !c("iso_code", "location", "date"),
    names_to = "indicator",
    values_to = "value"
  )

ggplot(owid_long_tbl, aes(x = date, y = value, colour = iso_code)) +
  geom_point(size = 0.5) +
  facet_wrap(vars(indicator), scales = "free_y") +
  theme_light()





