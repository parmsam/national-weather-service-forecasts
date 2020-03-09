# Created by Sam Parm on 2019-05-27
# Validated by NAME on YEAR-MT-DY
# Purpose: Pull weather data from national weather service using their api
# Production Schedule (if program is to be run on a regular basis):
# Limitations and Warnings: 
# Data Source Info: 
#API documentation:
#https://forecast-v3.weather.gov/documentation
#API data pull documentation:
#https://cran.r-project.org/web/packages/jsonlite/vignettes/json-apis.html
#1000 Largest US Cities By Population With Geographic Coordinates:
#https://public.opendatasoft.com/explore/dataset/1000-largest-us-cities-by-population-with-geographic-coordinates/table/?sort=-rank
#https://gist.github.com/Miserlou/c5cd8364bf9b2420bb29

# Program Derived From "other_program_name.R" (if applicable)
# Program Flow Description (high level review of the steps of the program) ; ----
#  1) Load libraries and define key parameters
#  2) Import top 1000 city long/lat data
#  3) First api call 
#  4) Second api call
#  5) Final data slicing
#  X) Clean up. 

# Leave mark at beginning of program log see when the run started (if needed)
#print("###############################################")
#paste("Run started at", Sys.time())
#print("###############################################")

# 1) Load libraries and define key constants, formats, etc. ; ----
#### PROJECT CODE GOES HERE 
#load libraries
library(rio)
library(tidyverse)
library(jsonlite)
library(httr)

# 2) import city data ----
city_list <- 
  import("https://raw.githubusercontent.com/parmsam/national-weather-service-forecasts/master/1000-largest-us-cities-by-population-with-geographic-coordinates.csv") %>% 
  separate(Coordinates, into=c("Long","Lat"),sep=regex(","))  %>% 
  mutate(city_state=paste0(City,", ",State))

city_of_interest="Indianapolis, Indiana"

city_data <- city_list %>% 
  filter(grepl(city_of_interest,city_state)) %>% 
  select(City,Long,Lat) %>% top_n(1); city_data

base_url = "https://api.weather.gov/points/"
long_lat = paste0(city_data$Long,",", city_data$Lat)
frst_url <- paste0(base_url,long_lat);frst_url

# 3) first call to get unique forecast api request ----
req<-httr::GET(frst_url)
json <- httr::content(req, as = "text")
weather_dat <- fromJSON(json)

forecast_url <- weather_dat$properties$forecast

# 4) second api call to get forecast data for city of interest ----
req<-httr::GET(forecast_url)
json <- httr::content(req, as = "text")
weather_dat <- fromJSON(json)

# 5) lastly, pull apert tonight/tmrw/rest week weather data from rest data ----
ext_forecast <- weather_dat$properties$periods %>% select(name,temperature,temperatureUnit,
                        windSpeed,windDirection,shortForecast)

# X) Clean up. ----
# Delete all objects that were created to clean up environment
# Uncomment when ready to run
#rm(list=ls())

# Leave mark at end of program to see when the run ended (if needed)
#print("###############################################")
#paste("Run ended at", Sys.time())
#print("###############################################")




                                  
