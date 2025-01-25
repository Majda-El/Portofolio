required_packages <- c("tidyverse", "lubridate", "forecast", "tseries", "rugarch", 
                       "tsibble", "caret", "Metrics", "modeltime", "readr", "readxl", "xts","zoo","MSwm","Metrics","PerformanceAnalytics","ggplot2","tseries")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}
setwd("C:/Users/Majda/OneDrive/Desktop/AEF/Timeseries/Project")
Masi <- read.csv("MASI DATA.csv", stringsAsFactors = FALSE)
str(Masi)
Masi$Date <- as.Date(Masi$Date, format = "%m/%d/%Y")
Masi$Price<-as.numeric(gsub(",","",Masi$Price))
Masi$Open<-as.numeric(gsub(",","",Masi$Open))
Masi$High<-as.numeric(gsub(",","",Masi$High))
Masi$Low<-as.numeric(gsub(",","",Masi$Low))
Masi$Change..<-as.numeric(gsub("%","",Masi$Change..))/100
Masi$Vol.<-NULL
summary(Masi)
Masi[order(Masi$Date), ]
if (!require("xts")) install.packages("xts")
library(xts)
price_ts <- xts(Masi$Price, order.by = Masi$Date)
str(price_ts)
summary(price_ts)
n <- length(price_ts)
train_size <- floor(0.8 * n)
train_set <- price_ts[1:train_size]
test_set <- price_ts[(train_size + 1):n]
cat("Training set size:", length(train_set), "\n")
cat("Testing set size:", length(test_set), "\n")
plot(train_set, main = "Price Time Series", ylab = "Price", xlab = "Date", col = "black")
if (!require("tseries")) install.packages("tseries")
library(tseries)
if (!require("forecast")) install.packages("forecast")
library(forecast)
par(mfrow = c(1, 2))  
acf(train_set, main = "ACF of Price Series")
pacf(train_set, main = "PACF of Price Series")
par(mfrow = c(1, 1)) 
adf_test <- adf.test(train_set)
print(adf_test)
kpss_test_original <- kpss.test(train_set)
print(kpss_test_original)
pp_test_original <- pp.test(train_set)
print(pp_test_original)
train_diff <- diff(train_set, differences = 1)
summary(train_diff)
train_diff<-na.omit(train_diff)
test_diff <- diff(test_set, differences = 1)
summary(test_diff)
test_diff<-na.omit(test_diff)
adf_test_Diff <- adf.test(train_diff)
print(adf_test_Diff)
kpss_test_Diff <- kpss.test(train_diff)
print(kpss_test_Diff)
pp_test_Diff <- pp.test(train_diff)
print(pp_test_Diff )
par(mfrow = c(1, 2))  
acf(train_diff, main = "ACF of Price Diff")
pacf(train_diff, main = "PACF of Price Diff")
par(mfrow = c(1, 1)) 
best_arima <- auto.arima(train_set, stepwise = TRUE, approximation = FALSE)
summary(best_arima)
manual_arima_model <- arima(train_set, order = c(2, 1, 2))
summary(manual_arima_model)
install.packages(c("Metrics", "xts", "forecast"))
library(Metrics)
library(xts)
library(forecast)
manual_forecast <- forecast(manual_arima_model, h = length(test_diff))
auto_forecast <- forecast(best_arima, h = length(test_diff))
manual_forecast_xts <- xts(manual_forecast$mean, order.by = index(test_diff))
auto_forecast_xts <- xts(auto_forecast$mean, order.by = index(test_diff))
manual_mae <- mae(test_diff, manual_forecast_xts)
auto_mae <- mae(test_diff, auto_forecast_xts)
manual_rmse <- rmse(test_diff, manual_forecast_xts)
auto_rmse <- rmse(test_diff, auto_forecast_xts)
model_comparison <- data.frame(
  Model = c("ARIMA(1,1,3)", "ARIMA(2,1,2)"),
  AIC = c(AIC(best_arima), AIC(manual_arima_model)),
  BIC = c(BIC(best_arima), BIC(manual_arima_model)),
  MAE = c(auto_mae, manual_mae),
  RMSE = c(auto_rmse, manual_rmse)
)
print(model_comparison)
checkresiduals(best_arima)
checkresiduals(manual_arima_model)
plot(test_diff, main = "ARIMA Forecasts Comparison", col = "black", ylab = "Price", xlab = "Date")
lines(auto_forecast_xts, col = "blue", lty = 2)
lines(manual_forecast_xts, col = "red", lty = 3)
legend("topright", legend = c("Actual", "ARIMA(1,1,3)", "ARIMA(2,1,2)"),
       col = c("black", "blue", "red"), lty = c(1, 2, 3))
autoplot(auto_forecast) + ggtitle("Auto ARIMA Forecast")
autoplot(manual_forecast) + ggtitle("Manual ARIMA Forecast")
auto_forecast_xts <- xts(auto_forecast$mean, order.by = index(test_diff))
manual_forecast_xts <- xts(manual_forecast$mean, order.by = index(test_diff))


if (!require("MSwM")) install.packages("MSwM")
library(MSwM)
train_df <- data.frame(
  y = as.numeric(train_diff),
  x = lag(as.numeric(train_diff), 1),
  Date = index(train_diff))
base_model <- lm(y ~ x, data = train_df)
msm_model_2 <- msmFit(base_model, k = 2, sw = rep(TRUE, 3))
summary(msm_model_2)
transition_probs <- msm_model_2@transMat
print(transition_probs)
smoothed_probs <- msm_model_2@Fit@smoProb
matplot(smoothed_probs, type = "l", lty = 1, col = 1:2,
        ylab = "Probability", xlab = "Index",
        main = "Smoothed Regime Probabilities")
legend("topright", legend = c("Regime 1", "Regime 2"),
       col = 1:2, lty = 1, bty = "n")
coefficients_regime1 <- msm_model_2@Coef[1, ]
coefficients_regime2 <- msm_model_2@Coef[2, ]
regime_probabilities <- msm_model_2@Fit@smoProb
x_values <- train_df$x
intercept_regime1 <- coefficients_regime1[1]
slope_regime1 <- coefficients_regime1[2]
intercept_regime2 <- coefficients_regime2[1]
slope_regime2 <- coefficients_regime2[2]
fitted_regime1 <- intercept_regime1 + slope_regime1 * x_values
fitted_regime2 <- intercept_regime2 + slope_regime2 * x_values
fitted_values <- regime_probabilities[, 1] * fitted_regime1 +
  regime_probabilities[, 2] * fitted_regime2
observed_values <- train_df$y
plot(observed_values, type = "l", col = "black",
     main = "Observed vs Fitted Values",
     ylab = "Values", xlab = "Index")
lines(fitted_values, col = "blue", lty = 2)
legend("topright", legend = c("Observed", "Fitted"),
       col = c("black", "blue"), lty = c(1, 2), bty = "n")
residuals_msm <- train_df$y - fitted_values
summary(residuals_msm)
length(train_df$y)
length(fitted_values)
str(msm_model_2)
forecast_msw <- forecast(msm_model_2, h = length(test_diff))
residuals_msm <- train_df$y - fitted_values
rss_msm <- sum(residuals_msm^2)
n <- length(train_df$y)
p <- length(msm_model_2@Coef[1, ]) + length(msm_model_2@Coef[2, ])
aic_msm <- n * log(rss_msm / n) + 2 * p
bic_msm <- n * log(rss_msm / n) + p * log(n)
cat("AIC for MSM: ", aic_msm, "\n")
cat("BIC for MSM: ", bic_msm, "\n")
observed_values <- as.numeric(observed_values)
fitted_values <- as.numeric(fitted_values)
rmse_msm <- sqrt(mean((observed_values - fitted_values)^2))
print(rmse_msm)
msm_mae <- mean(abs(observed_values - fitted_values))
print(msm_mae)
msm_rmse <- sqrt(mean((observed_values - fitted_values)^2))
print(msm_rmse)


model_comparison <- data.frame(
  Model = c("ARIMA(1,1,3)", "ARIMA(2,1,2)", "Markov-Switching"),
  AIC = c(AIC(best_arima), AIC(manual_arima_model), aic_msm),
  BIC = c(BIC(best_arima), BIC(manual_arima_model), bic_msm),
  MAE = c(auto_mae, manual_mae, msm_mae),
  RMSE = c(auto_rmse, manual_rmse, msm_rmse)
)
print(model_comparison)
