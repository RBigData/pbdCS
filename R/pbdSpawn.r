#' Server Launcher
#' 
#' Launcher for the pbdR server.
#' 
#' @description
#' This function is a simple wrapper around the system() command.  As such,
#' data is not shared between the calling R process and the batch processes
#' which execute the 'body' source.
#' 
#' @param nranks 
#' The number of MPI ranks to launch.
#' @param mpicmd
#' The command to launch mpi as a string (e.g., "mpirun", "mpiexec", 
#' "aprun", ...).
#' @param bcaster
#' The method used by the servers to communicate.  Options are "zmq"
#' for ZeroMQ-based communication, or "mpi" for 
#' @param port
#' A numeric value, or optionally for \code{pbdSpawn()}, the string
#' "random".  For numeric values, this is the port that will be
#' used for communication between the client and rank 0 of the 
#' servers.  If "random" is used, then a valid, random port
#' will be selected.
#' @param auto.dmat
#' Logical; deteremines if pbdDMAT should automatically be loaded
#' and \code{init.grid()} called.
#' 
#' @details
#' The \code{port} values between the client and server \emph{MUST}
#' agree.  If they do not, this can cause the client to hang.
#' 
#' The servers are launched via \code{pbdRscript()}.
#' 
#' The client is a specialized REPL that intercepts commands sent
#' through the R interpreter.  These commands are then sent from the
#' client to and evaluated on the servers.
#' 
#' The client communicates over ZeroMQ with MPI rank 0 (of the 
#' servers) using a REQ/REP pattern.  Both commands (from client to
#' server) and returns (from servers to client) are handled in this
#' way.  Once a command is sent from the client to MPI rank 0,
#' that command is then "broadcasted" from MPI rank 0 to the other
#' MPI ranks.  The method of broadcast is handled by the input
#' \code{bcaster}.  If \code{bcaster="mpi"}, then \code{MPI_bcast}
#' is used to transmit the command.  Otherwise (\code{bcaster="zmq"})
#' uses ZeroMQ with a PUSH/PULL pattern.  The MPI method is probably
#' epsilon faster, but it will busy-wait.  The ZeroMQ bcast method
#' will not busy wait, in addition to the other benefits ZeroMQ
#' affords; thus, \code{bcaster="zmq"} is the default.
#' 
#' To shut down the servers and the client, use the command \code{exit()}
#' from the remoter package.
#' 
#' @examples
#' \dontrun{
#' library(pbdCS)
#' pbd_launch_servers()
#' pbd_launch_client()
#' }
#' 
#' @seealso \code{\link{pbdRscript}}
#' @export
# port=55555, remote_port=55556, bcaster="zmq", password=NULL, maxretry=5, secure=has.sodium(), log=TRUE, verbose=FALSE, showmsg=FALSE
pbdSpawn <- function(nranks=2, mpicmd="mpirun", bcaster="zmq", port="random", auto.dmat=FALSE)
{
  if (is.character(port))
  {
    if (port == "random")
      port <- random_port()
  }
  else
    stop("")
  
  ### TODO check port
  bcaster <- match.arg(tolower(bcaster), c("zmq", "mpi"))
  
  rscript <- paste0("
    suppressPackageStartupMessages(library(pbdCS))
    pbdCS::pbdserver(bcaster=\"", bcaster, "\")
    finalize()
  ")
  
  pbdRscript(body=rscript, mpicmd=mpicmd, nranks=nranks, auto=TRUE, pid=FALSE, wait=FALSE, auto.dmat=auto.dmat)
  
  invisible(TRUE)
}
