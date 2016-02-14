pbdenv$prompt <- "pbdR"
pbdenv$remote_port <- 55556
pbdenv$bcast_method <- "zmq"
pbdenv$get_remote_addr <- TRUE

pbdenv$remote_context <- NULL
pbdenv$remote_socket <- NULL


## pbd_sanitize: finalize()

# pbd_bcast_mpi <- function(msg) bcast(msg, rank.source=0)
pbd_bcast_mpi <- function(msg) 
{
  spmd.bcast.message(msg, rank.source = 0)
}

pbd_bcast_zmq <- function(msg)
{
  if (comm.size() > 1)
  {
    if (comm.rank() == 0)
    {
      for (rnk in 1:(comm.size()-1))
        send.socket(pbdenv$remote_socket, data=msg)
    }
    else
    {
      msg <- receive.socket(pbdenv$remote_socket)
    }
  }
  
  msg
}

pbd_bcast <- function(msg)
{
  if (pbdenv$bcast_method == "mpi")
    msg <- pbd_bcast_mpi(msg=msg)
  else if (pbdenv$bcast_method == "zmq")
    msg <- pbd_bcast_zmq(msg=msg)
  
  return(msg)
}




pbd_eval <- function(input, whoami, env)
{
  set.status(continuation, FALSE)
  set.status(lasterror, NULL)
  
  if (comm.rank() == 0)
  {
    if (pbdenv$debug)
      cat("Awaiting message:  ")
    
    msg <- receive.socket(pbdenv$socket)
    
    if (pbdenv$debug)
      cat(msg, "\n")
  }
  else
    msg <- NULL
  
  msg <- pbd_bcast(msg)
  barrier() # just in case ...
  
  msg <- pbd_eval_filter_server(msg=msg)
  
  ret <- 
  withCallingHandlers(
    tryCatch({
        pbdenv$visible <- withVisible(eval(parse(text=msg), envir=env))
      }, interrupt=pbd_interrupt, error=pbd_error
    ), warning=pbd_warning
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
    
    send.socket(pbdenv$socket, pbdenv$status)
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



pbd_repl_init <- function()
{
  if (!get.status(pbd_prompt_active))
    set.status(pbd_prompt_active, TRUE)
  else
  {
    cat("The pbd repl is already running!\n")
    return(FALSE)
  }
  
  if (pbdenv$whoami == "local")
    cat("please wait a moment for the servers to spin up...\n")
  
  if (pbdenv$get_remote_addr)
    pbd_get_remote_addr()
  
  ### Initialize zmq
  if (pbdenv$whoami == "local")
  {
    pbdenv$context <- init.context()
    pbdenv$socket <- init.socket(pbdenv$context, "ZMQ_REQ")
    addr <- pbdZMQ::address(pbdenv$remote_addr, pbdenv$port)
    connect.socket(pbdenv$socket, addr)
    
    cat("\n")
  }
  else if (pbdenv$whoami == "remote")
  {
    ### Order very much matters!
    if (pbdenv$debug)
    {
      if (comm.size() == 1)
        cat("WARNING:  You should restart with mpirun and more than 1 MPI rank.\n")
      
      if (comm.rank() == 0)
        cat("Hello! This is the server; please don't type things here!\n\n")
    }
    
    if (comm.rank() == 0)
    {
      serverip <- getip()
      invisible(bcast(serverip, rank.source=0))
      
      ### client/server
      pbdenv$context <- init.context()
      pbdenv$socket <- init.socket(pbdenv$context, "ZMQ_REP")
      bind.socket(pbdenv$socket, paste0("tcp://*:", pbdenv$port))
    }
    else
      serverip <- bcast()
    
    if (pbdenv$bcast_method == "zmq")
    {
      if (comm.size() > 1)
      {
        if (comm.rank() == 0)
        {
          ### rank 0 setup for talking to other ranks
          pbdenv$remote_context <- init.context()
          pbdenv$remote_socket <- init.socket(pbdenv$remote_context, "ZMQ_PUSH")
          bind.socket(pbdenv$remote_socket, paste0("tcp://*:", pbdenv$remote_port))
        }
        else
        {
          ### other ranks
          pbdenv$remote_context <- init.context()
          pbdenv$remote_socket <- init.socket(pbdenv$remote_context, "ZMQ_PULL")
          connect.socket(pbdenv$remote_socket, paste0("tcp://", serverip, ":", pbdenv$remote_port))
        }
      }
    }
  }
  
  
  return(TRUE)
}



#' pbd_repl
#' 
#' The REPL for the client/server.
#' 
#' @description
#' This is exported for clean access reasons; you shoud not directly
#' use this function.
#' 
#' @param env 
#' Environment where repl evaluations will take place.
#'
#' @export
pbd_repl <- function(env=sys.parent())
{
  ### FIXME needed?
  if (!interactive() && pbdenv$whoami == "local")
    stop("You should only use this interactively")
  
  if (!pbd_repl_init())
    return(invisible())
  
  
  ### the repl
  while (TRUE)
  {
    input <- character(0)
    set.status(continuation, FALSE)
    set.status(visible, FALSE)
    
    while (TRUE)
    {
      pbdenv$visible <- withVisible(invisible())
      input <- pbd_readline(input=input)
      
      pbd_eval(input=input, whoami=pbdenv$whoami, env=env)
      
      if (get.status(continuation)) next
      
      pbd_repl_printer()
      
      ### Should go after all other evals and handlers
      if (get.status(should_exit))
      {
        set.status(pbd_prompt_active, FALSE)
        set.status(should_exit, FALSE)
        return(invisible())
      }
      
      break
    }
  }
  
  set.status(pbd_prompt_active, FALSE)
  set.status(should_exit, FALSE)
  
  return(invisible())
}
