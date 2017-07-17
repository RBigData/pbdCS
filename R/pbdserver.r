#' Server Launcher
#' 
#' Launcher for the pbdCS server.  The launcher should be executed
#' in batch using something like \code{mpirun}.
#' 
#' @details
#' TODO
#' 
#' @param port
#' The port (number) that will be used for communication between 
#' the client and server.  The port value for the client and server
#' must agree.
#' @param remote_port
#' TODO
#' @param bcaster
#' TODO
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
pbdserver <- function(port=55555, remote_port=55556, bcaster="zmq", password=NULL, maxretry=5, secure=has.sodium(), log=TRUE, verbose=FALSE, showmsg=FALSE)
{
  if (comm.rank() != 0)
    password <- NULL # don't want to run getPass() on other ranks
  
  if (length(port) == 1 && port == 0)
    
  
  validate_port(port, WARN=TRUE)
  validate_port(remote_port)
  assert_mpi(port != remote_port)
  assert_mpi(is.string(bcaster))
  assert_mpi(is.null(password) || is.string(password))
  assert_mpi(is.posint(maxretry))
  assert_mpi(is.flag(secure))
  assert_mpi(is.flag(log))
  assert_mpi(is.flag(verbose))
  assert_mpi(is.flag(showmsg))
  
  comm.match.arg(tolower(bcaster), c("zmq", "mpi"))
  
  if (interactive())
    comm.stop("You must launch pbdserver() in batch (non-interactively)")
  
  if (!log && verbose)
  {
    comm.warning("logging must be enabled for verbose logging! enabling logging...")
    log <- TRUE
  }
  
  if (!has.sodium() && secure)
    comm.stop("secure servers can only be launched if the 'sodium' package is installed")
  
  pbd_reset_state()
  
  set(whoami, "remote")
  set(bcast_method, bcaster)
  set(port, port)
  set(remote_port, remote_port)
  set(password, pwhash(password))
  set(secure, secure)
  set(kill_interactive_server, FALSE)
  
  set(serverlog, log)
  set(verbose, verbose)
  set(showmsg, showmsg)
  if (log)
    set(logfile, logfile_init())
  
  mpilogprint(paste("*** Launching", ifelse(getval(secure), "secure", "UNSECURE"), "pbdR server ***"), preprint="\n\n")
  ### TODO
  # ips <- remoter_getips()
  # logprint(paste("                           Internal IP: ", ips$ip_in), timestamp=FALSE)
  # logprint(paste("                           External IP: ", ips$ip_ex), timestamp=FALSE)
  mpilogprint(paste("                           Port:        ", port), timestamp=FALSE)

  
  rm("port", "password", "maxretry", "showmsg", "secure", "log", "verbose")
  invisible(gc())
  
  eval(parse(text = "suppressMessages(library(remoter, quietly=TRUE))"), envir = globalenv())
  eval(parse(text = "suppressMessages(library(pbdCS, quietly=TRUE))"), envir = globalenv())
  
  pbd_repl_server()
  pbdMPI::finalize()
  
  invisible(TRUE)
}







##TODO pbd_sanitize: finalize()




pbd_server_eval <- function(input, whoami, env)
{
  set.status(continuation, FALSE)
  set.status(lasterror, NULL)
  
  if (comm.rank() == 0)
  {
    msg <- remoter_receive()
    mpilogprint(level="RMSG", msg[length(msg)], checkshowmsg=TRUE)
  }
  else
    msg <- NULL
  
  msg <- pbd_bcast(msg)
  barrier() # just in case ...
  
  ### Run first-time checks
  if (length(msg)==1 && msg == magicmsg_first_connection)
  {
    if (comm.rank() == 0)
    {
      test <- remoter_check_password_remote()
      if (!test) return(invisible())
      remoter_check_version_remote()
    }
    
    barrier()
    return(invisible())
  }
  
  # TODO
  # msg <- pbd_eval_filter_server(msg=msg)
  
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
    
    remoter_send(getval(status))
  }
}



pbd_get_remote_addr <- function()
{
  if (comm.rank() == 0)
  {
    context <- zmq$Context()
    socket <- context$socket("ZMQ_REQ")
    socket$connect(address("localhost", .pbdenv$port))
    socket$send(getip("internal"))
    socket$receive()
    socket$disconnect()
    rm(socket);rm(context)
    invisible(gc())
  }
  
  invisible()
}



pbd_init_server <- function()
{
  # if (.pbdenv$get_remote_addr)
  #   pbd_get_remote_addr()
  
  ### Order very much matters!
  if (comm.rank() == 0)
  {
    serverip <- getip("internal")
    bcast(serverip, rank.source=0)
    
    set(context, pbdZMQ::init.context())
    set(socket, pbdZMQ::init.socket(getval(context), "ZMQ_REP"))
    pbdZMQ::bind.socket(getval(socket), address("*", getval(port)))
  }
  else
    serverip <- bcast()
  
  
  if (getval(bcast_method) == "zmq" && comm.size() > 1)
  {
    if (comm.rank() == 0)
    {
      ### rank 0 setup for talking to other ranks
      set(remote_context, pbdZMQ::init.context())
      set(remote_socket, pbdZMQ::init.socket(getval(remote_context), "ZMQ_PUSH"))
      pbdZMQ::bind.socket(getval(remote_socket), address("*", getval(remote_port)))
    }
    else
    {
      ### other ranks
      set(remote_context, pbdZMQ::init.context())
      set(remote_socket, pbdZMQ::init.socket(getval(remote_context), "ZMQ_PULL"))
      pbdZMQ::connect.socket(getval(remote_socket), address(serverip, getval(remote_port)))
    }
  }
  
  
  # if (getval(auto.dmat))
  # {
  #   suppressPackageStartupMessages(library(pbdSLAP))
  #   suppressPackageStartupMessages(library(pbdBASE))
  #   suppressPackageStartupMessages(library(pbdDMAT))
  # }
  
  return(TRUE)
}



pbd_repl_server <- function(env=globalenv())
{
  remoter_repl_server(env=env, initfun=pbd_init_server, evalfun=pbd_server_eval)
  
  invisible()
}
