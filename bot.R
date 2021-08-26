##########################################################################
## Initial Setup
##########################################################################
## Load libraries
#devtools::install_github("ropensci/rtweet")
library(rtweet)
library(tidyverse)
library(lubridate)
library(readr)
library(pingr)

## Bot specific parameters
work_dir <- "~/Desktop/Twitter_Bots/daohaus"
c_key <- "**"								## Consumer Key
c_sec <- "**"								## Consumer Secret
access_token <- "**"						## Access Token
access_token_secret <- "**"					## Access Token Secret
app_name <- "UberDAO Media Booster"										## Name of the app created to fetch tokens
account_handle = "uber_haus"											## Handle of the account we would use to post retweets
ad_text = " which tracks DAO News and retweets them through this channel 24x7. Follow to be always up to date with everything happening in the DAO world. Retweet and spread the word."

## Some sleep time in case bot start coincide with the system reboot and OS is not fully prepared.
Sys.sleep(30)

## Set working directory
setwd(work_dir)

## Stop script if no internet
if(!(pingr::is_online())) stop("No Internet")

## One time setup to create and save token
if(!("twitter_token_daohaus.rds" %in% list.files()))
{
	twitter_token <- create_token(app = app_name ,consumer_key = c_key,consumer_secret = c_sec,access_token = access_token,access_secret = access_token_secret,set_renv=FALSE)
	saveRDS(twitter_token,"twitter_token_daohaus.rds")
}

## Load twitter Token
twitter_token <- readRDS("twitter_token_daohaus.rds")
##########################################################################
##########################################################################


##########################################################################
## Collect Twitter Handles and their start points
## Parse and prepare starting point from handles mentioned in accounts.csv
##########################################################################
if(!("handles_cover.Rdata" %in% list.files()))
{
	## Read the data set
	Handles_Table <- read_csv("accounts.csv")
	handles_cover <- Handles_Table[!is.na(Handles_Table$`Handle`),c("Name","Handle")]
	handles_cover <- handles_cover[match(unique(handles_cover$`Handle`),handles_cover$`Handle`),]
	handles_cover$`Last Tweet` <- NA
	idx_i <- 1

	## Loop initialisation and iterate to collect starting points for all handles
	last_tweet_id <- NULL
	while(TRUE)
	{
		## Print handle index
		message(idx_i)

		## Stop script if no internet
		if(!(pingr::is_online())) stop("No Internet")
		
		last_tweet_id <- suppressWarnings(get_timeline(handles_cover$`Handle`[idx_i],n=1,check=FALSE,token=twitter_token)$status_id)
		handles_cover$`Last Tweet`[idx_i] <- ifelse(is.null(last_tweet_id),NA,last_tweet_id)
		idx_i <- idx_i + 1
		last_tweet_id <- NULL
		if(idx_i > nrow(handles_cover)) break()
	}

	## Save Out file
	saveRDS(handles_cover,"handles_cover.Rdata")
}
handles_cover <- readRDS("handles_cover.Rdata")
##########################################################################
##########################################################################

##########################################################################
## Defining function to post a tweet/retweet
##########################################################################
post_retweet <- function(id,destroy=FALSE,token=twitter_token)
{
	## build query
    query <- paste0("statuses/",ifelse(destroy,"unretweet","retweet"),"/", id)
    ## make URL
    url <- rtweet:::make_url(query = query)
    ## send request
    r <- rtweet:::TWIT(get = FALSE, url, token)
}
##########################################################################
##########################################################################

##########################################################################
## Defining tracking df to track ad display intervals
##########################################################################
if(!("ad_df.Rdata" %in% list.files()))
{
	ad_df <- data.frame(Hour = c(0,6,12,18), Posted = rep(FALSE,4))
	saveRDS(ad_df,"ad_df.Rdata")
}
ad_df <- readRDS("ad_df.Rdata")
##########################################################################
##########################################################################

##########################################################################
## Loop over all handles
##########################################################################
## Initiate loop index and start loop
idx = 1
while(TRUE)
{
	## Print handle index
	message(idx)
	
	## Main algo to retweet and ad display
	tryCatch({
				## Get tweets
				latest_tweets <- get_timeline(handles_cover$`Handle`[idx],n=10,check=FALSE,since_id=ifelse(is.na(handles_cover$`Last Tweet`[idx]),1,handles_cover$`Last Tweet`[idx]),token=twitter_token)
					
				## Process the tweets if there are any
				if(nrow(latest_tweets)>0)
				{
					## Subset the original tweets i.e removing retweets etc.
					latest_tweets_l <- latest_tweets[is.na(latest_tweets$reply_to_status_id) & !latest_tweets$is_retweet,]

					## Process the tweets if there are any left
					if(nrow(latest_tweets_l)>0)
					{
						## Print into console for retweets done
						message(paste0(latest_tweets_l$screen_name[1]," : ",nrow(latest_tweets_l)," : ",Sys.time()))

						## Main algo to retweet and ad display
						for(idx_t in 1:nrow(latest_tweets_l))
						{
							post_retweet(latest_tweets_l$status_id[idx_t],token=twitter_token)

							## Check and post ad if time interval permits
							# if(!ad_df$Posted[max(which(hour(Sys.time())>=ad_df$Hour))])
							# {
							# 	# Post ad
							# 	post_tweet(
							# 				status = paste0(
							# 									"This tweet from @",
							# 									latest_tweets_l$screen_name[idx_t],
							# 									" is retweeted via @",
							# 									account_handle,
							# 									ad_text
							# 								),
							# 				in_reply_to_status_id = latest_tweets_l$status_id[idx_t],
							# 				token=twitter_token
							# 			)

							# 	## Change it's tracker value
							# 	ad_df$Posted[max(which(hour(Sys.time())>=ad_df$Hour))] <- TRUE
							# 	saveRDS(ad_df,"ad_df.Rdata")
							# }

						}
					}

					## Update the latest id
					handles_cover$`Last Tweet`[idx] <- latest_tweets$status_id[1]
					saveRDS(handles_cover,"handles_cover.Rdata")
				}

				## Increment index to cover all coins 
				idx <- idx+1

				## Reset all ad trackers except the current ones
				ad_df$Posted[-max(which(hour(Sys.time())>=ad_df$Hour))] <- FALSE
				saveRDS(ad_df,"ad_df.Rdata")
			}, 	error=function(e){
									## Stop script if no internet or move to next coin
									if(!(pingr::is_online())) stop("No Internet")
									idx <- idx+1
								}
			)

	## Sleep to maintain interval so as to not cross api limit
	Sys.sleep(1)

	## Break loop when done all coins
	if(idx > nrow(handles_cover)) break()
}
