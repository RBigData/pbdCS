#' Server Launcher
#' 
#' Launcher for the pbdCS server.
#' 
#' @details
#' TODO
#' 
#' @param port
#' The port (number) that will be used for communication between 
#' the client and server.  The port value for the client and server
#' must agree.
#' @param password
#' A password the client must enter before the user can process
#' commands on the server.  If the value is \code{NULL}, then no
#' password checking takes place.
#' @param maxretry
#' The maximum number of retries for passwords before shutting
#' everything down.
#' @param secure
#' Logical; enables encryption via public key cryptography of
#' the 'sodium' package is available.
#' @param log
#' Logical; enables some basic logging in the server.
#' @param verbose
#' Logical; enables the verbose logger.
#' @param showmsg
#' Logical; if TRUE, messages from the client are logged
#' 
#' @return
#' Returns \code{TRUE} invisibly on successful exit.
#' 
#' @export
pbdserver <- function(port=55555, bcaster="zmq", auto.dmat=TRUE, password=NULL, maxretry=5, secure=has.sodium(), log=TRUE, verbose=FALSE, showmsg=FALSE)
{
  validate_port(port)
  assert_that(is.string(bcaster))
  assert_that(is.flag(auto.dmat))
  assert_that(is.null(password) || is.string(password))
  assert_that(is.infinite(maxretry) || is.count(maxretry))
  assert_that(is.flag(secure))
  assert_that(is.flag(log))
  assert_that(is.flag(verbose))
  assert_that(is.flag(showmsg))
  
  if (!log && verbose)
  {
    warning("logging must be enabled for verbose logging! enabling logging...")
    log <- TRUE
  }
  
  if (!has.sodium() && secure)
    stop("secure servers can only be launched if the 'sodium' package is installed")
  
  reset_state()
  
  set(whoami, "remote")
  set(bcast_method, bcaster)
  set(auto.dmat, auto.dmat)
  set(serverlog, log)
  set(verbose, verbose)
  set(showmsg, showmsg)
  set(port, port)
  set(password, password)
  set(secure, secure)
  
  logprint(paste("*** Launching", ifelse(getval(secure), "secure", "UNSECURE"), "server ***"), preprint="\n\n")
  
  rm("port", "password", "maxretry", "showmsg", "secure", "log", "verbose")
  invisible(gc())
  
  pbd_repl_server()
  
  invisible(TRUE)
}







##TODO pbd_sanitize: finalize()




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
  
  if (getval(auto.dmat))
    suppressPackageStartupMessages(library(pbdDMAT))
  
  return(TRUE)
}



pbd_repl_server <- function(env=sys.parent())
{
  remoter_repl_server(env=env, initfun=pbd_init_server, evalfun=pbd_server_eval)
  invisible()
}
