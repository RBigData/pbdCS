#' Client Launcher
#' 
#' Connect to a pbdR server (launch the client).
#' 
#' @details
#' An alias of the remoter function \code{client()}.
#' 
#' @param prompt
#' The prompt to display differentiating the pbd client
#' from a basic R prompt.
#' @param ...
#' Additional arguments passed to \code{remoter::client}.
#' See \code{?remoter::client} for details.
#' 
#' @export
pbdclient <- function(prompt="pbdR", ...) remoter::client(prompt=prompt, ...)
