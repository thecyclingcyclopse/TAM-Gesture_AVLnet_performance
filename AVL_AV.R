################################################################################
# 1. INSTALL AND LOAD PACKAGES #################################################
################################################################################
## Installs pacman ("package manager") if needed
require(pacman)
if (!require("pacman")) install.packages("pacman")
## Loads additional packages
pacman::p_load(pacman, BBEST, data.table, dplyr, GGally, ggplot2, ggstatsplot,
               ggthemes, ggvis, httr, lubridate, plotly, psych, rio, rmarkdown,
               shiny, stringr, tibble, tidyr)
################################################################################
# 2. Set Working Dir & Import Data ############################################# 
################################################################################
## Define Parent Working Directory
setwd("~/TAM-Similarities-Data/Datasets/")
### Importing Videolist XLSX
vidlist <- import("Videoliste_TAM_gesture.xlsx")
## Defining Sub Directory
setwd("AVLnet_sim/")
### CSV Import - Similarity Audio Video
simAV <- import("sim_Audio_Video.csv")
################################################################################
# 3. Stats! ####################################################################
################################################################################
## Create statistics object and set column names
simAV_statob <- data.frame(matrix(0, ncol = 2, nrow = 673))
x <- c("Filename", "abstr_code")
colnames(simAV_statob) <- x
rm(x)
## Insert additional information to domain specific stats object
simAV_statob$"Filename" <- simAV$"V1"
## extract abstractness code from filename
simAV_statob <- simAV_statob %>% 
  group_by(Filename) %>% 
    mutate(abstr_code = str_split(
      Filename, pattern = "_", simplify = TRUE)[1]) %>%
        ungroup()
vidlist <- vidlist %>%
  separate(Gesamt, into = c("Filename", "Extension"), sep = "\\.")
simAV_statob <- simAV_statob %>%
  left_join(., select(vidlist, Filename, `Rating Abstractness (18 VP)`),
            by = "Filename")
rm(vidlist)
## Calculate statistical values
simAV_deviance <- as.data.frame(
  simAV %>%  
    summarize(
      across(
        c(`mp_dt_schrupfen-x_dunkel`:`dk_dt_zettelaufdemboden_hell`), 
        list(sd = sd, mini = min, maxi = max, mean = mean, median = median), 
        .names = "{.col}.{.fn}")) %>%
    pivot_longer(
      everything(), 
      names_to = c(".value", "var"),
      names_sep = "\\.") %>%
    t() # transpose
)
rm(simAV)
## rename column names
simAV_deviance <- simAV_deviance[-1,]
simAV_deviance$Filename <- rownames(simAV_deviance)
rownames(simAV_deviance) <- 1:nrow(simAV_deviance)
colnames(simAV_deviance) <- c("sd", "mini", "maxi", "mean", "median", "Filename")
## merge statistical values into statistics object
simAV_statob <- simAV_statob %>%
  left_join(., simAV_deviance, by = "Filename")
rm(simAV_deviance)
simAV_statob$sd <- as.numeric(simAV_statob$sd)
simAV_statob$mini <- as.numeric(simAV_statob$mini)
simAV_statob$maxi <- as.numeric(simAV_statob$maxi)
simAV_statob$mean <- as.numeric(simAV_statob$mean)
simAV_statob$median <- as.numeric(simAV_statob$median)
simAV_statob <- simAV_statob %>%
  mutate_at(vars(abstr_code), factor)
colnames(simAV_statob) <- c("Filename", "abstr_code", "abstr_rate", "sd", "mini",
                            "maxi", "mean", "median")
## export stats object to working directory
write.csv(simAV_statob, "AVL_stats_simAV.csv")
## ANOVA
summary(aov(mean ~ abstr_code, simAV_statob))
################################################################################
# 4. Plots! ####################################################################
################################################################################
## GGStatPlot
ggstatsplot::ggbetweenstats(
  data = simAV_statob, 
  x = abstr_code, 
  y = mini,
  xlab = "abstraction_code",
  ylab = "minimum",
  messages = FALSE
)
ggstatsplot::ggbetweenstats(
  data = simAV_statob, 
  x = abstr_code, 
  y = mean,
  xlab = "abstraction_code",
  ylab = "mean",
  messages = FALSE
)
ggstatsplot::ggbetweenstats(
  data = simAV_statob, 
  x = abstr_code, 
  y = maxi,
  xlab = "abstraction_code",
  ylab = "maximum",
  messages = FALSE
)