# RR_ggplot

# TO DO:
# Clean the data                                    - DONE
# policzyć ile trwały poszczególne odstępy RR 
# (odległości między sąsiednimi zespołami R)        - DONE
# na tej podstawie chwilową czynność serca,         - DONE - element TCA
#                                                 (temporary cardiac activity)
# potem średnią czynność serca dla: 
#   minut,                                          - DONE - TCA_M
#   godzin,                                         - DONE - TCA_h
#   pory dnia (dzień/noc - przyjmij 22:00 - 07:00)  - DONE - TCA_day
#   i całego zapisu                                 - DONE - TCA_allTime
# wszystko przedstawić na wykresie od czasu         - COULD BE DONE BETTER FOR SURE SOMEHOW
#  podobny wykres dla odsetka pobudzeń komorowych   _ DONE
# przedstawić na wykresie zmienność odstępów RR 
# w zależności od typu pobudzenia.                  - DONE FOR ITS SUMS

# Dependencies ------------------------------------------------------------

library(dplyr)
library(tibble)
library(ggplot2)

# Setup -------------------------------------------------------------------

data_path <- './data/01_2017_12_08_16_28_00.txt'

# Load --------------------------------------------------------------------

# Tidying the data

data <- as_tibble(read.csv(data_path, header = FALSE, sep = '\t'))

patients_ID <- '01'
lab_start_date <- '2017/08/16'
lab_start_time <- '16:28:00'

# Just to clean the data
data <- data %>%
  rename(time_stamp = V1, flag_type = V2)

info <- data[1,1]
# Pulls the value from the tibble
info <- pull(info)

data <- data[-1,]

data <- data %>%
  add_column(patients_ID, info, lab_start_date, lab_start_time, .before = 1) %>%
  print(n = 10)

# Format lab_start_date to date format
data$lab_start_date <- as.Date(data$lab_start_date)

# Generates correct integer units
data$time_stamp <- as.numeric(sub(",", ".", data$time_stamp, fixed = TRUE))

# ---------------------------------------------------------------------------

# RR space between each flag type

# Calculates differences between each row value, expect the '0' value which
# added later
RR_spaces_missing <- diff(data$time_stamp)

# Gets diff() value for the first time_stamp value
first_ts <- data$time_stamp[1]

# Adds first diff() for first row as the RR_spaces is one value too short
RR_spaces_correct <- append(first_ts, RR_spaces_missing)

# Creates new column which will mean spaces between each RR type
data$RR_space_time <- RR_spaces_correct

# ---------------------------------------------------------------------------

# Time elements

# Calculates for how many minutes was the lab taking place
time_seconds <- max(data$time_stamp)

time_minutes <- time_seconds / 60L

time_hours <- time_minutes / 60L

# Knowing the fact the the lab started at 16:28:00 and that it was taking place
# for ~50 hours we can state that the lab was taking place during 
# two full night time periods - assuming that the night is time between
# 22:00 - 07:00 hours we can make a statemant that the lab was taking place
# for 9 hours x2 during the night so 18 hours during the night in generall

time_night <- 18L

# Day time in hours
time_day <- time_hours - time_night

# Day time in seconds
time_day_s <- time_day * 3600

# Cardiac Activity

time_normal <- sum(data$RR_space_time[data$flag_type == 'N'])

# Temporary cardiac activity value 

TCA <- 1/data$RR_space_time
data$TCA <- TCA
TCA_ammount <- length(TCA)

# Calculating average TCA for hours/day time/whole lab time (seconds)
# Adding them to the tibble too

TCA_allTime <-  sum(TCA) / TCA_ammount 
TCA_day <- TCA_allTime /  time_day
TCA_h <- TCA_allTime / time_hours
TCA_m <- TCA_allTime / time_minutes

data$TCA_allTime <- TCA_allTime
data$TCA_day <- TCA_day
data$TCA_h <- TCA_h
data$TCA_m <- TCA_m

# Cardiac chambers arousals

chambers_time <- data$RR_space_time[data$flag_type == 'V']

chambers_TCA<- data$TCA[data$flag_type == 'V']

df_chambers <- tibble(ch_RR = chambers_time, ch_TCA = chambers_TCA)

# How does RR changes in every other flag type

RR_changes_N <- sum(data$RR_space_time[data$flag_type == 'N'])

RR_changes_V <- sum(data$RR_space_time[data$flag_type == 'V'])

RR_changes_S <- sum(data$RR_space_time[data$flag_type == 'S'])

RR_changes_X <- sum(data$RR_space_time[data$flag_type == 'X'])

RR_changes_U <- sum(data$RR_space_time[data$flag_type == 'U'])

df_RRchanges <- tibble(RR_type = c('RR_changes_V', 'RR_changes_S',
                        'RR_changes_X', 'RR_changes_U'),
                       RR_sum = c(RR_changes_V, RR_changes_S,
                       RR_changes_X, RR_changes_U))

# ---------------------------------------------------------------------------

# Plots

time_stamp_plot <- data$time_stamp

# Unclear plot
ggplot(data = data, aes(x = time_stamp, y = TCA)) +
  geom_line() +
  theme_bw()

# Basic R plot
plot(data$time_stamp, data$TCA)

# a little bit easier to visualize
ggplot(data = data, aes(x = time_stamp, y = TCA)) +
  geom_area() +
  theme_bw()

# For all variables
df <- tibble(TCA_type = c('TCA_allTime','TCA_day', 'TCA_h', 'TCA_m'),
spike = c(1.104741, 0.0345, 0.0221, 0.000368))


ggplot(data = df, aes(x = TCA_type, y = spike)) +
  geom_bar(stat="identity") +
  geom_text(aes(label = spike), vjust=-0.3, size=3.5)+
  theme_bw()

# Cardiac chambers arousals graph
ggplot(data = df_chambers, aes(x = ch_RR, y = ch_TCA)) +
  geom_line() +
  theme_bw()

# RR general lengths to the type of RR_type
ggplot(data = df_RRchanges, aes(x = RR_type, y = RR_sum)) +
  geom_bar(stat="identity") +
  geom_text(aes(label = RR_sum), vjust=-0.3, size=3.5)+
  theme_bw()
