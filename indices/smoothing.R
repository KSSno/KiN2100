# Define Gaussian kernel function
kerf <- function(z) {
  gkf <- exp(-z^2 / 2.0) / sqrt(2 * pi)
  return(gkf)
}

# Smooting function
smoooth_wkw <- function(datatosmooth, h=9) {
  
  
  # Number of data points
  ct <- length(datatosmooth)
  
  # Bandwidth: h (9 equals approx. 30-year smoothing)
  
  z <- smoothed <- NULL
  # Perform kernel smoothing
  for (i in 1:ct) {
    for (j in 1:ct) {
      z[j] <- kerf((i - j) / h)
    }
    smoothed[i] <- sum(z * datatosmooth) / sum(z)
  }
  
  return(smoothed)
}


