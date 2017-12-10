#' @export
comm.print = function(x, all.rank = .pbd_env$SPMD.CT$print.all.rank, rank.print = .pbd_env$SPMD.CT$rank.source, 
  comm = .pbd_env$SPMD.CT$comm, quiet = .pbd_env$SPMD.CT$print.quiet, 
  flush = .pbd_env$SPMD.CT$msg.flush, barrier = .pbd_env$SPMD.CT$msg.barrier, 
  con = stdout(), ...) 

{
  rank = pbdMPI::comm.rank()
  
  if (isTRUE(all.rank))
  {
    p = capture.output(pbdMPI::comm.print(x, all.rank, rank.print, comm, quiet, flush, barrier, con, ...))
    p.0 = gather(p)
    
    if (rank == 0)
      cat(paste0(sapply(p.0, function(i) paste0(i, collapse="\n")), collapse="\n"))
  }
  else
  {
    if (rank.print == 0)
      pbdMPI::comm.print(x, FALSE, 0, comm, quiet, flush, barrier, con, ...)
    else
    {
      p = capture.output(pbdMPI::comm.print(x, all.rank, rank.print, comm, quiet, flush, barrier, con, ...))
      if (rank == rank.print)
        send(p, rank.dest=0)
      else if (rank == 0)
      {
        p.0 = recv(rank.source=rank.print)
        cat(paste0(p.0, collapse="\n"))
      }
    }
  }
}
