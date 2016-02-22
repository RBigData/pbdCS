pbd_reset_state <- function()
{
  invisible(eval(parse(text = "remoter:::reset_state()")))
  set(auto.dmat, TRUE)
  set(remote_port, 55556)
  set(bcast_method, "zmq")
  set(get_remote_addr, TRUE)
  
  set(remote_context, NULL)
  set(remote_socket, NULL)
  
  invisible()
}



### remoter imports
set <- eval(parse(text = "remoter:::set"))
getval <- eval(parse(text = "remoter:::getval"))
get.status <- eval(parse(text = "remoter:::get.status"))
set.status <- eval(parse(text = "remoter:::set.status"))


remoter_warning <- eval(parse(text = "remoter:::remoter_warning"))
remoter_error <- eval(parse(text = "remoter:::remoter_error"))
remoter_repl_server <- eval(parse(text = "remoter:::remoter_repl_server"))
validate_port <- eval(parse(text = "remoter:::validate_port"))

logfile_init <- eval(parse(text = "remoter:::logfile_init"))
logprint <- eval(parse(text = "remoter:::logprint"))
mpilogprint <- function(msg, checkverbose=FALSE, checkshowmsg=FALSE, preprint="", level="")
{
  if (comm.rank() == 0)
    logprint(msg, checkverbose, checkshowmsg, preprint, level)
}

remoter_send <- eval(parse(text = "remoter:::remoter_send"))
remoter_receive <- eval(parse(text = "remoter:::remoter_receive"))

remoter_check_password_remote <- eval(parse(text = "remoter:::remoter_check_password_remote"))
remoter_check_version_remote <- eval(parse(text = "remoter:::remoter_check_version_remote"))
magicmsg_first_connection <- eval(parse(text = "remoter:::magicmsg_first_connection"))


shellexec.wcc <- eval(parse(text = "pbdZMQ:::shellexec.wcc"))
