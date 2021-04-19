# helper function: remove accents
unaccent <- function(text) {
  text <- gsub("['`^~\"]", " ", text)
  text <- iconv(text, to="ASCII//TRANSLIT//IGNORE")
  text <- gsub("['`^~\"]", "", text)
  return(text)
}

# helper function to estimate overdispersino parameter:
fit_psi_extrapolation <- function(vect, alpha, obs_to_use = 4){
  mu <- pmax(alpha*vect[length(vect) - (obs_to_use:1) - 1], 0.2)
  obs <- pmax(vect[length(vect) - (obs_to_use:1)], 0)
  if(all(obs == 0)) return(30)
  fct <- function(psi) -sum(dnbinom(obs, mu = mu, size = psi, log = TRUE))
  opt <- optimize(fct, interval = c(0, 100))
  return(opt$minimum)
}

# sample path
sample_path <- function(X0, alpha, psi, nsim){
  X <- matrix(ncol = 4, nrow = nsim)
  for(i in 1:nsim){
    X[i, 1] <- rnbinom(1, mu = alpha*X0, size = psi)
    for(t in 2:4) X[i, t] <- rnbinom(1, mu = alpha*X[i, t - 1], size = psi)
  }
  return(X)
}

# naive forecasts of incident deaths:
baseline_forecast_extrapolation <- function(dat_weekly, loc, target, forecast_date){

  probs <- c(0.01, 0.025, 1:19/20, 0.975, 0.99)
  dat_location_weekly <- subset(dat_weekly, location == loc &
                                  date <= forecast_date &
                                  weekdays(date) == "Saturday")
  loc_name <- dat_location_weekly$location_name[1]

  # use last observation as predictive mean:
  last_five_obs <- tail(dat_location_weekly[, paste0("inc_", target)], 5)
  # set alpha to last multiplicative increase or 1, if pattern across last three is changing:
  alpha <- ifelse((last_five_obs[3] > last_five_obs[4] &
                    last_five_obs[4] > last_five_obs[5]) |
                    (last_five_obs[3] < last_five_obs[4] &
                       last_five_obs[4] < last_five_obs[5]),
                  last_five_obs[5]/last_five_obs[4],
                  1)

  # estimate overdispersion parameter from last 4 observations:
  psi <- fit_psi_extrapolation(dat_location_weekly[, paste0("inc_", target)], alpha = alpha, obs_to_use = 4)

  # sample paths:
  sim <- sample_path(X0 = last_five_obs[5], alpha = alpha, psi = psi, nsim = 100000)

  ### write out incidence forecasts:

  # write out last observed values
  obs_inc <- data.frame(forecast_date = forecast_date,
                        target = paste((-1:0), "wk ahead inc", target),
                        target_end_date = tail(dat_location_weekly$date, 2),
                        location = loc,
                        type = "observed",
                        quantile = NA,
                        value = tail(dat_location_weekly[, paste0("inc_", target)], 2),
                        location_name = dat_location_weekly$location_name[1])

  # point forecasts
  point_inc <- data.frame(forecast_date = forecast_date,
                          target = paste(1:4, "wk ahead inc", target),
                          target_end_date = max(dat_location_weekly$date) + (1:4)*7,
                          location = loc,
                          type = "point",
                          quantile = NA,
                          value = apply(sim, 2, median),
                          location_name = dat_location_weekly$location_name[1])

  # quantiles
  quantiles_inc <- data.frame(forecast_date = forecast_date,
                              target = rep(paste(1:4, "wk ahead inc", target), each = length(probs)),
                              target_end_date = rep(max(dat_location_weekly$date) +
                                                      (1:4)*7, each = length(probs)),
                              location = loc,
                              type = "quantile",
                              quantile = rep(probs, 4),
                              value = c(
                                quantile(sim[, 1], probs = probs),
                                quantile(sim[, 2], probs = probs),
                                quantile(sim[, 3], probs = probs),
                                quantile(sim[, 4], probs = probs)
                              ),
                              location_name = dat_location_weekly$location_name[1])

  ### cumulative forecasts:
  # move to cumulative sums:
  sim_cum <- sim
  sim_cum[, 1] <- sim_cum[, 1] + tail(dat_location_weekly[, paste0("cum_", target)], 1)
  for(i in 2:4) sim_cum[, i] <- sim_cum[, i - 1] + sim_cum[, i]

  # store last observations:
  obs_cum <- data.frame(forecast_date = forecast_date,
                        target = paste((-1:0), "wk ahead cum", target),
                        target_end_date = tail(dat_location_weekly$date, 2),
                        location = loc,
                        type = "observed",
                        quantile = NA,
                        value = tail(dat_location_weekly[, paste0("cum_", target)], 2),
                        location_name = dat_location_weekly$location_name[1])

  # point forecasts:
  point_cum <- data.frame(forecast_date = forecast_date,
                          target = paste(1:4, "wk ahead cum", target),
                          target_end_date = max(dat_location_weekly$date) + (1:4)*7,
                          location = loc,
                          type = "point",
                          quantile = NA,
                          value = apply(sim_cum, 2, median),
                          location_name = dat_location_weekly$location_name[1])

  # quantiles:
  quantiles_cum <- data.frame(forecast_date = forecast_date,
                              target = rep(paste(1:4, "wk ahead cum", target), each = length(probs)),
                              target_end_date = rep(max(dat_location_weekly$date) + (1:4)*7,
                                                    each = length(probs)),
                              location = loc,
                              type = "quantile",
                              quantile = rep(probs, 4),
                              value = c(
                                quantile(sim_cum[, 1], probs = probs),
                                quantile(sim_cum[, 2], probs = probs),
                                quantile(sim_cum[, 3], probs = probs),
                                quantile(sim_cum[, 4], probs = probs)
                              ),
                              location_name = dat_location_weekly$location_name[1])

  ret <- rbind(obs_inc, point_inc, quantiles_inc,
               obs_cum, point_cum, quantiles_cum)

  return(ret)
}
