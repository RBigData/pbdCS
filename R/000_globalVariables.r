### For R CMD check
utils::globalVariables(c(
  "serverlog", "verbose", "showmsg", "shellexec", "context", "socket",
  "port", "bcast_method", "remote_socket", "remote_port", "auto.dmat",
  "continuation", "lasterror", "visible", "status", "whoami", 
  "serverlog", "kill_interactive_server", "pbd_launch_client",
  "remote_context", "get_remote_addr", "maxattempts", "secure",
  "should_exit", "remoter_prompt_active", "shouldwarn", "num_warnings",
  "logfile", "password", "remote_addr",
  ### FIXME shouldn't be here; find and remove them...
  "pbdenv", "pbd_launch"
))
