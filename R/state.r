pbd_reset_state <- function()
{
  reset_state()
  set(auto.dmat, TRUE)
  set(remote_port, 55556)
  set(bcast_method, "zmq")
  set(get_remote_addr, TRUE)
  
  set(remote_context, NULL)
  set(remote_socket, NULL)
  
  invisible()
}





set <- function(var, val)
{
  name <- as.character(substitute(var))
  .pbdenv[[name]] <- val
  invisible()
}

getval <- function(var)
{
  name <- as.character(substitute(var))
  .pbdenv[[name]]
}

get.status <- function(var)
{
  name <- as.character(substitute(var))
  .pbdenv$status[[name]]
}

set.status <- function(var, val)
{
  name <- as.character(substitute(var))
  .pbdenv$status[[name]] <- val
  invisible()
}
