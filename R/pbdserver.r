pbdenv$prompt <- "pbdR"
pbdenv$remote_port <- 55556
pbdenv$bcast_method <- "zmq"
pbdenv$get_remote_addr <- TRUE

pbdenv$remote_context <- NULL
pbdenv$remote_socket <- NULL


## pbd_sanitize: finalize()




pbd_server_eval <- function(input, whoami, env)
{
  set.status(continuation, FALSE)
  set.status(lasterror, NULL)
  
  if (comm.rank() == 0)
    msg <- receive()
  else
    msg <- NULL
  
  msg <- pbd_bcast(msg)
  barrier() # just in case ...
  
  msg <- pbd_eval_filter_server(msg=msg)
  
  ret <- 
  withCallingHandlers(
    tryCatch({
        withVisible(eval(parse(text=msg), envir=env))
      }, error=remoter_error
    ), warning=remoter_warning
  )
  
  
  if (comm.rank() == 0)
  {
    if (!is.null(ret))
    {
      set.status(visible, ret$visible)
      
      if (!ret$visible)
        set.status(ret, NULL)
      else
        set.status(ret, utils::capture.output(ret$value))
    }
    
    send(getval(status))
  }
}



pbd_get_remote_addr <- function()
{
  if (pbdenv$whoami == "local")
  {
    context <- zmq$Context()
    socket <- context$socket("ZMQ_REP")
    socket$bind(address("*", pbdenv$port))
    pbdenv$remote_addr <- socket$receive()
    socket$send("got it")
    
    ### TODO store address and port in ~/.pbdR/remote
    socket$close()
    rm(socket);rm(context)
    invisible(gc())
  }
  else if (pbdenv$whoami == "remote"  &&  comm.rank() == 0)
  {
    context <- zmq$Context()
    socket <- context$socket("ZMQ_REQ")
    socket$connect(address("localhost", pbdenv$port))
    socket$send(getip())
    socket$receive()
    socket$disconnect()
    rm(socket);rm(context)
    invisible(gc())
  }
  
  invisible()
}






pbd_init_server <- function()
{
  # if (pbdenv$get_remote_addr)
  #   pbd_get_remote_addr()
  
  ### Order very much matters!
  if (comm.rank() == 0)
  {
    serverip <- getip()
    bcast(serverip, rank.source=0)
    
    set(context, init.context())
    set(socket, init.socket(getval(context), "ZMQ_REP"))
    bind.socket(getval(socket), address("*", getval(port)))
  }
  else
    serverip <- bcast()
  
  
  
  if (getval(bcast_method) == "zmq" && comm.size() > 1)
  {
    if (comm.rank() == 0)
    {
      ### rank 0 setup for talking to other ranks
      set(remote_context, init.context())
      set(remote_socket, init.socket(getval(remote_context), "ZMQ_PUSH"))
      bind.socket(getval(remote_socket), address("*", getval(remote_port)))
    }
    else
    {
      ### other ranks
      set(remote_context, init.context())
      set(remote_socket, init.socket(getval(remote_context), "ZMQ_PULL"))
      connect.socket(getval(remote_socket), address(serverip, getval(remote_port)))
    }
  }
  
  
  return(TRUE)
}



pbd_repl_server <- function(env=sys.parent())
{
  remoter_repl_server(env=env, initfun=pbd_init_server, evalfun=pbd_server_eval)
  invisible()
}
