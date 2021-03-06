#' Create weighting category from data
#' 
#' This function creates an individual weighting category with known marginal 
#' probabilities (E.g., age group, eye color.), but unlike \code{category()} it 
#' creates them from a dataframe instead of being directly assigned. One or more 
#' of these are built and fed into \code{universe()}.
#' 
#' @param name Name given to weighting category, character. 
#' Must have exact match in the column names of data you intend to weight.
#' @param df Data frame containing data you intend to weight.
#' @param prev.wgt Variable name of weight used to calculate bucket proportions in \code{`df`}. Optional.
#' 
#' @importFrom dplyr mutate select enquo group_by summarise ungroup %>%
#' @importFrom rlang !!
#' @importFrom tidyr gather
#' @importFrom tibble tibble
#' 
#' @return A nested \code{tibble} with special class \code{category}.
#' 
#' @examples 
#' data(weight_me)
#' 
#' category_inherit(
#'   name = "costume",
#'   df = dplyr::filter(weight_me, satisfied == "No")
#' )
#' 
#' category_inherit(
#'   name = "transport",
#'   df = dplyr::filter(weight_me, satisfied == "No"),
#'   prev.wgt = prev_weight
#' )
#' 
#' @export
category_inherit <- function(name, df, prev.wgt) {
    
    # verify parameters
    if (!is.character(name) || length(name) != 1) {
        stop("`name` must be a character vector of length one.")
    }
    
    if (nchar(name) == 0) {
        stop("String length of `name` must be greater than zero.")
    }
    
    if (!is.data.frame(df)) {
        stop("'df' must be an object of class 'data.frame'")
    }
    
    # assign prevWeight value of 1 or prev.wgt if specified 
    if (missing(prev.wgt) || !deparse(substitute(prev.wgt)) %in% names(df)) {
        
        df <- 
            df %>%
            mutate(prevWeight = 1) %>%
            select(prevWeight, name)
        
    } else {
        
        prev.wgt <- enquo(prev.wgt)
        df <- 
            df %>%
            mutate(prevWeight = !! prev.wgt) %>%
            select(prevWeight, name)
    }
    
    # create weighted proportions from data
    targs <- 
        df %>%
        gather(name, value, -1) %>%
        group_by(value) %>%
        summarise(wgt_n = sum(prevWeight)) %>%
        mutate(wgt_prop = wgt_n / sum(wgt_n)) %>%
        ungroup()
    
    # create nested tibble structure
    out <- 
        tibble(
            category = name,
            data = list(
                tibble(buckets = targs$value,
                       targ_prop = targs$wgt_prop)
            )
        )
    
    # assign class    
    class(out) <- c(class(out), "category")
    
    return(out)
    
}

utils::globalVariables(c("prevWeight", "value", "wgt_n"))