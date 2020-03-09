library(shiny)
library(tidyverse)
library(rio)
library(jsonlite)
library(httr)
library(DT)

# Pull data ----
city_list <- 
  import("https://raw.githubusercontent.com/parmsam/national-weather-service-forecasts/master/1000-largest-us-cities-by-population-with-geographic-coordinates.csv") %>% 
  separate(Coordinates, into=c("Long","Lat"),sep=regex(","))  %>% 
  mutate(city_state=paste0(City,", ",State))

# Define UI for application that ouptuts table of weather forecast
ui <- fluidPage(
    
    # Application title
    titlePanel("National Weather Service Forecast Data for Major Cities"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("variable_1", "Pick or type the major city  you want weatherforecast info on",
                        #choices=list("",name = c("Cho"="",unique(Dat$Resource_name))),
                        choices=c("Choose one"="",sort(unique(city_list$city_state))),
                        #options = list(placeholder = 'Please select an option below'),
                        selected = "Indianapolis, Indiana"
                        #verbatimTextOutput("selected")
            )
        ),

        # Show a data table of the weather forecast prediction for weather.gov
        mainPanel(
            DT::dataTableOutput("data")
        )
    )
)

# Define server logic required to output forecast
server <- function(input, output) {
    datPull <- reactive({
        city_data <- city_list %>% 
            filter(grepl(input$variable_1,city_state)) %>% 
            select(City,Long,Lat) %>% top_n(1) %>% data.frame()
        base_url = "https://api.weather.gov/points/"
        long_lat = paste0(city_data$Long,",", city_data$Lat)
        frst_url <- paste0(base_url,long_lat);frst_url
        
        #first call to get unique forecast api request 
        req<-httr::GET(frst_url)
        json <- httr::content(req, as = "text")
        weather_dat <- fromJSON(json)
        
        forecast_url <- weather_dat$properties$forecast
        
        #second api call to get forecast data for city of interest
        req<-httr::GET(forecast_url)
        json <- httr::content(req, as = "text")
        weather_dat <- fromJSON(json)
        
        #pull tonight/tmrw/rest week weather data from rest data
        ext_forecast <- weather_dat$properties$periods %>% 
            select(name,temperature,temperatureUnit,
                   windSpeed,windDirection,shortForecast)
    })
    
    output$data <- DT::renderDataTable({ 
        data<-datPull()
        DT::datatable(data,list(mode = "single", target = "cell"),escape = FALSE)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
