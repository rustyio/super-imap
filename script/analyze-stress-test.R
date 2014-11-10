#!/usr/bin/env Rscript

library(ggplot2)

###
### READ DATA
###

## Read CSV files.
cat("Reading CSV files.")
generated <- read.csv('./log/stress/generated_emails.csv')
fetched <- read.csv('./log/stress/fetched_emails.csv')
events <- read.csv('./log/stress/events.csv')

## There are multiple processed files, one for each server.
paths <- list.files(path = "./log/stress/",
                    pattern = "processed_emails_.*.csv",
                    full.names = TRUE)
processed <- do.call(rbind, lapply(paths, FUN=function(path) {
    df <- read.csv(path)
    names(df) <- c("time", "email", "message.id")
    df$time <- as.POSIXct(df$time)
    return(df)
}))
processed <- processed[order(processed$time), ]

## Rename columns.
names(generated) <- c("time", "email", "message.id")
names(fetched) <- c("time", "email", "message.id")
names(processed) <- c("time", "email", "message.id")
names(events) <- c("time", "email", "event")

## Normalize column values.
generated$time <- as.POSIXct(generated$time)
fetched$time <- as.POSIXct(fetched$time)
processed$time <- as.POSIXct(processed$time)
events$time <- as.POSIXct(events$time)

## Split out chaotic events.
chaotic.events <- events[grepl("chaos", events$event),]

## Add count columns.
generated$count <- 1
fetched$count <- 1
processed$count <- 1
chaotic.events$count <- 1

## Add total columns.
generated$total <- cumsum(generated$count)
fetched$total <- cumsum(fetched$count)
processed$total <- cumsum(processed$count)
chaotic.events$total <- cumsum(chaotic.events$count)


###
### SAVE A PLOT
###

cat("Generating plots.\n")

x.limits <- c(min(generated$time), max(processed$time))

title = "# of Emails Generated, Fetched, & Processed Over Time"
p1 <- ggplot() +
    ggtitle(title) +
    xlab("Time") +
    ylab("Count") +
    xlim(x.limits) +
    guides(color = guide_legend(title = NULL)) +
    geom_line(aes(generated$time, generated$total, col="Generated")) +
    geom_line(aes(fetched$time, fetched$total, col="Fetched")) +
    geom_line(aes(processed$time, processed$total, col="Processed")) +
    geom_line(aes(chaotic.events$time, chaotic.events$total, col="Chaos")) +
    theme(legend.position = "left")

title = "Chaotic Events"
p2 <- ggplot() +
    ggtitle(title) +
    xlab("Time") +
    ylab("Chaotic Events") +
    xlim(x.limits) +
    geom_point(aes(chaotic.events$time, chaotic.events$event))

## Save the plots.
cat("Saving plots.\n")
pdf("./stress-test-results.pdf")
print(p1)
print(p2)
dev.off()
