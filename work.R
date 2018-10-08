setwd('C:/Users/geoff/nhl-predictions')
df = read.csv('./nhldata20052017.csv')
df = df[-which(df$season == 2018), ]
df$t.rest = as.numeric(as.character(df$t.rest))
df$to.rest = as.numeric(as.character(df$to.rest))
df$t.goals = as.numeric(as.character(df$t.goals))
df$to.goals = as.numeric(as.character(df$to.goals))
df$t.line = as.numeric(as.character(df$t.line))
df$to.line = as.numeric(as.character(df$to.line))

df$shoot.out = as.numeric(as.character(df$shoot.out))
df$t.period.scores3 = as.numeric(as.character(df$t.period.scores3))
df$t.period.scores4 = as.numeric(as.character(df$t.period.scores4))
df$to.period.scores3 = as.numeric(as.character(df$to.period.scores3))
df$toperiod.scores4 = as.numeric(as.character(df$to.period.scores4))


linetoprob = function(line){
  if (is.na(line)) {
    return(line)
  }
  if (line > 0) {
    return( 100 / (line+100) )
  } else {
    return( -line/(-line+100) )
  }
}


opt.cut = function(perf, pred){
  cut.ind = mapply(FUN=function(x, y, p){
    d = (x - 0)^2 + (y-1)^2
    ind = which(d == min(d))
    c(sensitivity = y[[ind]], specificity = 1-x[[ind]], 
      cutoff = p[[ind]])
  }, perf@x.values, perf@y.values, pred@cutoffs)
}

library(dplyr)
df$one = 1
df = df %>% group_by(season, t.abbreviation) %>% mutate(t.cum_goals = cumsum(t.goals))
df = df %>% group_by(season, to.abbreviation) %>% mutate(to.cum_goals = cumsum(to.goals))

df = df %>% group_by(season, t.abbreviation) %>% mutate(t.cum_goals.allowed = cumsum(to.goals))
df = df %>% group_by(season, to.abbreviation) %>% mutate(to.cum_goals.allowed = cumsum(t.goals))

df$t.cum_goals.todate = df$t.cum_goals - df$t.goals
df$to.cum_goals.todate = df$to.cum_goals - df$to.goals
df$t.goals.pg = df$t.cum_goals.todate / (df$t.game.number-1)
df$to.goals.pg = df$to.cum_goals.todate / (df$to.game.number-1)

df$t.cum_goals.allowed.todate = df$t.cum_goals.allowed - df$to.goals
df$to.cum_goals.allowed.todate = df$to.cum_goals.allowed - df$t.goals
df$t.goals.allowed.pg = df$t.cum_goals.allowed.todate / (df$t.game.number-1)
df$to.goals.allowed.pg = df$to.cum_goals.allowed.todate / (df$to.game.number-1)

df$t.win_prob = df$t.line %>% lapply(linetoprob) %>% unlist %>% round(3)
df$to.win_prob = df$to.line %>% lapply(linetoprob) %>% unlist %>% round(3)
df$t.win_prob_scale = df$t.win_prob / (df$t.win_prob + df$to.win_prob) %>% round(3)
df$to.win_prob_scale = df$to.win_prob / (df$t.win_prob + df$to.win_prob) %>% round(3)
df$t.win = (df$t.goals > df$to.goals)

library(ROCR)
#df = df[df$home_ind == TRUE, ]
#df = df[floor(dim(df)[1]/2):dim(df)[1],]

#burn in of 10 games per season
df = df[which(df$t.game.number > 10 & df$to.game.number > 10), ]

#2 games had missing lines...delete
df = df[-which(is.na(df$t.line) | is.na(df$to.line)), ]


library(caret)
library(glmnet)

x = model.matrix(t.win ~ t.goals.pg + to.goals.pg + H + t.rest + to.rest + 
                   t.matchup.wins + t.matchup.losses + t.goals.allowed.pg + 
                   to.goals.allowed.pg + t.win_prob_scale, df)[,-1]
y = ifelse(df$t.win,1,0)

set.seed(41)
cv.lasso <- cv.glmnet(x, y, alpha = 1, family = "binomial")
glmnet = glmnet(x, y, family = "binomial", alpha=1, lambda = 0)
pred = predict(glmnet, type=c("response"), newx=x)

glm = glm(y ~ x, family="binomial")
summary(glm)
glm2 = glm(t.win ~  t.win_prob_scale, data = df, family="binomial")
summary(glm2)
pred = predict(glm, type=c("response"))


df$t.win_prob_pred = pred
# pred = df$win_prob
pred_ROCR = prediction(pred, df$t.win)
roc_ROCR = performance(pred_ROCR, measure="tpr", x.measure="fpr")
auc_ROCR = performance(pred_ROCR,measure="auc")@y.values[[1]] %>% round(3)
plot(roc_ROCR, main=paste("ROC Curve, AUC = ",auc_ROCR), colorize=TRUE)
abline(a=0, b= 1)


#gains/lift
perf <- performance(pred_ROCR,"lift","rpp")
plot(perf, main="lift curve", colorize=T)
library(gains)
gains = gains(y, pred, groups=10 )
optcut = opt.cut(roc_ROCR, pred_ROCR)
plot(x=gains$mean.prediction, y=gains$mean.resp)
abline(a=0,b=1)

acc.perf = performance(pred_ROCR, measure = "acc")
plot(acc.perf)
ind = which.max( slot(acc.perf, "y.values")[[1]] )
acc = slot(acc.perf, "y.values")[[1]][ind]
cutoff = slot(acc.perf, "x.values")[[1]][ind]
print(c(accuracy= acc, cutoff = cutoff))

cutoff = .5
df$pred_win = (df$win_prob > cutoff)
table(df$pred_win, df$win)
