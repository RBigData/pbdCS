send_remote <- function(data, send.more=FALSE)
{
  send.socket(getval(remote_socket), data=data, send.more=send.more)
}



receive_remote <- function()
{
  receive.socket(getval(remote_socket))
}



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
        send_remote(data=msg)
    }
    else
    {
      msg <- receive_remote()
    }
  }
  
  msg
}



pbd_bcast <- function(msg)
{
  if (.pbdenv$bcast_method == "mpi")
    msg <- pbd_bcast_mpi(msg=msg)
  else if (.pbdenv$bcast_method == "zmq")
    msg <- pbd_bcast_zmq(msg=msg)
  
  return(msg)
}
