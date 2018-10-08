library(elo)
data(tournament)
tournament = tournament

# setwd('C:/Users/geoff/nhl-predictions')
# df = read.csv('./nhldata20052017.csv')
# df = df[-which(df$season == 2018), ]
df$t.goals.reg = df$t.goals - df$t.period.scores4 - df$t.period.scores3 

df.elo = df[which(df$H == "True"), c("t.abbreviation","to.abbreviation","t.goals","to.goals","t.game.number", "to.game.number")]

colnames(df.elo) = c("team.Home", "team.Vistor", "points.Home", "points.Visitor","week")

 
hist(df$t.goals, freq=F)
lam = mean(df$t.goals,na.rm=TRUE)
dpois(1,)