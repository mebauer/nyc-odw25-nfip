#****************************************************************************
#Scientist: Tiffany Cousins
#Create Date: 3/24/2025
#Objective: NYC NFIP Claims
#****************************************************************************
rm(list = ls(all=TRUE))

#General Setup
library(tidyverse)
library(dplyr)
library(ggplot2)
library(scales)
library(openxlsx)
library(RColorBrewer)


options(scipen=999)

#set working directory
setwd("C://Users//tiffa//Desktop//NYC ODW 2025")

#bring in the NFIP Claims csv
NFIP_claims <- read.csv("02 Analysis//01 Input//nfip-claims-nyc.csv")

#------------------------Claims per Year---------------------------------
#create a table with number of claims and the amount of damage ($) per year
claimsperyear <- NFIP_claims %>%
  group_by(yearOfLoss) %>%
  summarise(countofclaims = n())

# plot number of claims and its trend
ggplot(claimsperyear, aes(x = yearOfLoss)) +
  # Bar chart for the number of claims
  geom_bar(aes(y = countofclaims), stat = "identity", fill = "#f2a236", color = "#d96d39", na.rm = TRUE) +  
  #add trend line
  geom_smooth(aes(y = countofclaims), method = "lm", color = "#5d4fad", linetype="dashed", se = FALSE)+
  # Scale the primary y-axis and adjust the secondary y-axis based on the scaling factor
  labs(title ="Total Number of Claims in NYC over Time",
       x="Year",
       y = "Number of Claims")+
  scale_y_continuous(labels = comma)
  theme_grey()

#------------------------Damage per Year---------------------------------
#create a table with amount of damage ($) per year
damageperyear <- NFIP_claims %>%
  group_by(yearOfLoss) %>%
  summarise(totaldamage = sum(buildingDamageAmount,na.rm = TRUE))

# plot damage and its trend
ggplot(damageperyear, aes(x = yearOfLoss)) +
  geom_line(aes(y = totaldamage), color = "#d96d39", size=1.5) +  
  #add trend line
  geom_smooth(aes(y = totaldamage), method = "lm", color = "#5d4fad", linetype="dashed", se = FALSE)+
  # Scale the primary y-axis and adjust the secondary y-axis based on the scaling factor
  labs(title ="Total Amount of Building Damage over Time",
       x="Year",
       y="Total Damage ($)")+
  scale_y_continuous(labels = dollar)+
  theme_grey()

#------------------------Claims and Damage by Flood Zone---------------------------------
#there are some blanks that we need to fill
NFIP_claims$ratedFloodZone[NFIP_claims$ratedFloodZone==""] <- "NA"

#create a table with number of claims and damage per flood zone
floodzones_summary <- NFIP_claims %>%
  group_by(ratedFloodZone) %>%
  summarise(countofclaims = n(),
            totaldamage = sum(buildingDamageAmount,na.rm = TRUE)) %>%
  mutate(FloodZone=recode(ratedFloodZone,
                          "B" = "Moderate-Risk Flood Zone",
                          "C" = "Low-Risk Flood Zones",
                          "D" = "Undetermined Risk Flood Zones",
                          "X" = "Moderate to Low Risk Flood Zones",
                          "NA" = "No Flood Zone Identified",
                          .default = "High-Risk Flood Zones"))

#re-summarize
floodzone_stats <- floodzones_summary %>%
  group_by(FloodZone) %>%
  summarise(countofclaims = sum(countofclaims),
            totaldamage = sum(totaldamage))

#number of claims per Flood Zone
ggplot(floodzone_stats, aes(x = FloodZone)) +
  geom_bar(aes(y = countofclaims), stat = "identity", fill = "#9866cc", color = "#281040", na.rm = TRUE)+
  labs(title ="Total Number of Claims per Flood Zone",
       x="Year",
       y="Number of Claims")+
  scale_y_continuous(labels = comma)+
  theme_grey()

#total damage per Flood Zone
ggplot(floodzone_stats, aes(x = FloodZone)) +
  geom_bar(aes(y = totaldamage), stat = "identity", fill = "#9866cc", color = "#281040", na.rm = TRUE)+
  labs(title ="Total Amount of Building Damage per Flood Zone",
       x="Year",
       y="Total Damage ($)")+
  scale_y_continuous(labels = dollar)+
  theme_grey()

#------------------------Claims and Damage by Flood Type---------------------------------
#create a table with number of claims and damage per flood type
floodtype_stats <- NFIP_claims %>%
  group_by(floodCharacteristicsIndicator) %>%
  summarise(countofclaims = n(),
            totaldamage = sum(buildingDamageAmount,na.rm = TRUE)) %>%
  mutate(FloodType=recode(floodCharacteristicsIndicator,
                          "1" = "Velocity Flow",
                          "2" = "Low-Velocity Flow or Ponding",
                          "3" = "Wave Action",
                          "4" = "Mudflow",
                          "5" = "Erosion")) %>%
  drop_na()

#total of claims by flood type
ggplot(floodtype_stats, aes(x = FloodType)) +
  geom_bar(aes(y = countofclaims), stat = "identity", fill = "#1fa5cf", color = "#1863bf", na.rm = TRUE)+
  labs(title ="Total Number of Claims by Flood Type",
       x="Flood Type",
       y="Number of Claims")+
  scale_y_continuous(labels = comma)+
  theme_grey()

#total of damage by flood type
ggplot(floodtype_stats, aes(x = FloodType)) +
  geom_bar(aes(y = totaldamage), stat = "identity", fill = "#1fa5cf", color = "#1863bf", na.rm = TRUE)+
  labs(title ="Total Amount of Building Damage by Flood Type",
       x="Flood Type",
       y="Total Damage ($)")+
  scale_y_continuous(labels = dollar)+
  theme_grey()

#------------------------Claims and Damage by Flood Event---------------------------------
NFIP_claims$floodEvent[NFIP_claims$floodEvent==""] <- "NA"

#create a table with number of claims and damage per flood event
floodevent_summary <- NFIP_claims %>%
  group_by(floodEvent) %>%
  summarise(countofclaims = n(),
            totaldamage = sum(buildingDamageAmount,na.rm = TRUE)) %>%
  mutate(FloodEventType=case_when(
    str_detect(floodEvent,"Hurricane") ~ "Hurricane",
    str_detect(floodEvent,"Tropical") ~ "Tropical Storm",
    .default = "non-Major Event"
  )) %>%
  filter(floodEvent!="NA")

#re-summarize
floodevent_stats <- floodevent_summary %>%
  group_by(FloodEventType)%>%
  summarise(countofclaims = sum(countofclaims),
            totaldamage = sum(totaldamage))

#plot total of claims by flood event
ggplot(floodevent_stats, aes(x = FloodEventType)) +
  geom_bar(aes(y = countofclaims), stat = "identity", fill = "#f2a236", color = "#d96d39", na.rm = TRUE)+
  labs(title ="Total Number of Claims by Flood Event Type",
       x="Flood Event Type",
       y="Number of Claims")+
  scale_y_continuous(labels = comma)+
  theme_grey()

#plot total of damage by flood type
ggplot(floodevent_stats, aes(x = FloodEventType)) +
  geom_bar(aes(y = totaldamage), stat = "identity", fill = "#f2a236", color = "#d96d39", na.rm = TRUE)+
  labs(title ="Total Amount of Building Damage by Flood Event Type",
       x="Flood Event Type",
       y="Total Damage ($)")+
  scale_y_continuous(labels = dollar)+
  theme_grey()

#------------------------Claims and Damage by Flood Type 2---------------------------------
FloodType2 <- NFIP_claims %>%
  filter(floodCharacteristicsIndicator == "2")

type2event <- FloodType2 %>% 
  group_by(floodEvent) %>%
  summarise(countofclaims = n(),
            totaldamage = sum(buildingDamageAmount,na.rm = TRUE))

type2floodzone <- FloodType2 %>% 
  group_by(ratedFloodZone) %>%
  summarise(countofclaims = n()) %>%
  mutate(FloodZone=recode(ratedFloodZone,
                          "B" = "Moderate-Risk Flood Zone",
                          "C" = "Low-Risk Flood Zones",
                          "D" = "Undetermined Risk Flood Zones",
                          "X" = "Moderate to Low Risk Flood Zones",
                          "NA" = "No Flood Zone Identified",
                          .default = "High-Risk Flood Zones"))

#------------------------ANALYSIS: Random for Fun----------------------------------- 
#number of claims and damage by zip code
zipcode_totaldamge <- NFIP_claims %>% 
  group_by(reportedZipCode) %>%
  summarise(countofclaims = n(),
            totaldamage= sum(buildingDamageAmount,na.rm = TRUE))

#number of events per year
eventsperyear <- NFIP_claims %>%
  group_by(yearOfLoss) %>%
  count(floodEvent)

#number of claims and damage per event per year
FloodTypeevent <- NFIP_claims %>%
  group_by(floodEvent, yearOfLoss) %>%
  summarise(countofclaims = n(),
            totaldamage= sum(buildingDamageAmount,na.rm = TRUE))

#just looking at events that are Hurricanes or Tropical Storms
HTS <- NFIP_claims %>%
  filter(str_detect(floodEvent,"Hurricane|Tropical")) %>% 
  group_by(yearOfLoss) %>%
  count(floodEvent)

#plotting the number of claims for each Hurricane and Tropical Storm 
ggplot(HTS, aes(x = yearOfLoss)) +
  # Bar chart for the number of claims
  geom_bar(aes(y = n), stat = "identity", fill = "#f2a236", color = "#d96d39", na.rm = TRUE) +
  #add events as a points
  geom_point(aes(y = n))+
  #add trend line
  geom_smooth(aes(y = countofclaims), method = "lm", color = "#5d4fad", linetype="dashed", se = FALSE)+
  # Scale the primary y-axis and adjust the secondary y-axis based on the scaling factor
  labs(title ="Claims over Time",
       x="Year",
       y = "Number of Claims")+
  theme_grey()
  
#plotting the overall number of claims through the years with points as the Hurricane and Tropical Storm events
graphcolors <- brewer.pal(9,"Set1")
names(graphcolors) <- levels(HTS$floodEvent)
custom_colors <- scale_colour_manual(name = "Weather Events", values = graphcolors)
# plot number of claims,its trend, and certain events
ggplot(claimsperyear) +
  geom_bar(aes(x = yearOfLoss, y = countofclaims), stat = "identity", fill = "#763e3f", color = "#2C1717", na.rm = TRUE)+
  geom_point(data = HTS, aes(x=yearOfLoss, y=n, color=floodEvent), size=2.5)+
  custom_colors +
  labs(title ="Total Number of Claims in NYC over Time",
       x="Year",
       y = "Number of Claims")+
  scale_y_continuous(labels = comma)
theme_grey()
 