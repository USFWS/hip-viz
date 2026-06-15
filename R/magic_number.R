# Create a function to magically format numbers
magic_number <-
  function(x) {
    
    a_thousand <- 1000
    ten_thousand <- 10000
    thousands <- 999999
    a_million <- 1000000
    a_billion <- 1000000000
    
    if (x > thousands & x < a_billion) {
      # Millions labeler
      scales::label_number(
        accuracy = 0.01, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x >= 999500 & x < a_million) {
      "999K"
    } else if (x >= ten_thousand & x < a_million) {
      # Thousands labeler
      scales::label_number(
        accuracy = 1, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x >= a_thousand & x < ten_thousand) {
      scales::label_number(
        accuracy = 0.1, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x > 0 & x < a_thousand) {
      x
    } else {
      "ERROR"
    }
  }

# Test magic_number() function
# purrr::map(
#   c(1, 10, 100, 999, 1000, 1200, 1900, 9900, 9999,
#     10000, 10100, 15321, 43256, 99999, 100000, 
#     101000, 145234, 456789, 499999, 500000, 501000,
#     678923, 789456, 899000, 989000, 999000, 999499,
#     999500, 999999, 1000000, 1000100, 1010000,
#     1234567, 1567890, 1700300, 9234100, 9999999,
#     10000000, 15000000, 99123456),
#   \(x) magic_number(x)
# )