kill <- function(pid)
{
  os <- get.os()
  
  if (same.str(os, "windows"))
    stop("doesn't work :[")
  else
  {
    if (checkpid(pid))
      system(paste("kill", pid))
    else
      warning(paste("pid=", pid, " does not exist", sep=""))
  }
  
  invisible()
}



checkpid <- function(pid)
{
  os <- get.os()
  
  if (same.str(os, "windows"))
    stop("doesn't work :[")
  else
  {
    x <- suppressWarnings(system(paste("kill -0", pid, "2>&1"), intern=TRUE))
    
    match <- grep(x=x, pattern="No such process")
    if (length(match) == 0)
      match <- 0L
    
    return( !as.logical(match) )
  }
}



is.int <- function(x)
{
  if (is.numeric(x))
  {
    if (x-as.integer(x) == 0)
      return( TRUE )
    else
      return( FALSE )
  }
  else
    return( FALSE )
}



same.str <- function(str1, str2)
{
  isTRUE(tolower(str1) == tolower(str2))
}



get.os <- function()
{
  Sys.info()["sysname"]
}



dirsep <- function()
{
  if (same.str(get.os(), "windows"))
    "\\"
  else
    "/"
}



assert_mpi <- function(..., env = parent.frame())
{
  test <- tryCatch(check(...), error=identity)
  if (!is.logical(test))
  {
    msg <- gsub(test, pattern="(^<assert|>$|Error: )", replacement="")
    comm.stop(msg, mpi.finalize=TRUE)
  }
  else
    TRUE
}
