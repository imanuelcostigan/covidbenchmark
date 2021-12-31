library(tidyverse)

# Get core data
url <- "https://github.com/owid/covid-19-data/raw/master/public/data/owid-covid-data.csv"
owid <- read_csv(url)

countries <- c("AUS", "NZL", "USA", "GBR", "CAN", "DEU", "FRA", "AUT", "BEL",
  "SGP", "DNK", "ISR", "ITA", "JPN", "KOR", "NLD", "FIN", "NOR", "SWE", "ESP",
  "CHE")
countries <- countries[order(countries)]
start_date <- as.Date("2021-09-01")
country_benchmarked <- "AUS"

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
    stringency_index,
    people_fully_vaccinated_per_hundred,
    total_boosters_per_hundred,
    # "Tests conducted per new confirmed case of COVID-19, given as a rolling
    #  7-day average (this is the inverse of positive_rate)"
    new_tests_smoothed_per_thousand,
    new_cases_smoothed_per_million,
    tests_per_case,
    hosp_patients_per_million, # stock, not flow.
    icu_patients_per_million,  # stock, not flow.
    new_deaths_smoothed_per_million
  ) |>
  fill(
    stringency_index,
    people_fully_vaccinated_per_hundred,
    total_boosters_per_hundred,
    new_tests_smoothed_per_thousand,
    new_cases_smoothed_per_million,
    tests_per_case,
    hosp_patients_per_million,
    icu_patients_per_million,
    new_deaths_smoothed_per_million
  ) |>
  pivot_longer(
    cols = !c("iso_code", "location", "date"),
    names_to = "indicator",
    values_to = "value"
  ) |>
  mutate(
    indicator = as_factor(indicator)
  )

owid_long_tbl |>
  group_by(iso_code, indicator) |>
  summarise(n = n(), notna = sum(!is.na(value)))

ggplot(owid_long_tbl, aes(x = date, y = value, colour = iso_code)) +
  geom_point(size = 0.5) +
  facet_wrap(vars(indicator), scales = "free_y") +
  theme_light() +
  theme(legend.position = "bottom")


owid_last_snap <- owid_long_tbl |>
  filter(date == max(date, na.rm = TRUE) - 3)
owid_country_bench <- owid_last_snap |>
  filter(iso_code == country_benchmarked)

owid_last_snap |>
  ggplot(aes(x = indicator, y = value)) + geom_boxplot()  +
  geom_boxplot(data = owid_country_bench, colour = "red") +
  facet_wrap(vars(indicator), scales = "free")




