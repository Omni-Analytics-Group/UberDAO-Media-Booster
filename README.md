# UberDAO-Media-Booster
To retweet tweets made via a list of selected handles.

## accounts.csv
Contains the handles to track and retweet their tweets.

## bot.R
Contains R code to start the bot track the current tweets and generate the info in `handles_cover.Rdata` and Twitter token in `twitter_token_daohaus.rds` and then on every repeated run start from that tracked info, Track any new tweets and retweet them.

## crontab_entry.txt
Crontab entry code to be added in cron file so that the bot is scheduled to run on fixed intervals. 

## About Us

[Omni Analytics Group](https://omnianalytics.io) is an incorporated group of passionate technologists who help others use data science to change the world. Our  practice of data science leads us into many exciting areas where we enthusiastically apply our machine learning, artificial intelligence and analysis skills. Our flavor for this month, the blockchain!  To learn more about what we do or just to have fun, join us over on [Twitter](https://twitter.com/OmniAnalytics).
