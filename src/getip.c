/*  Copyright (c) 2015, Drew Schmidt
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "platform.h"

#if !OS_WINDOWS
#include <sys/types.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <net/if.h>

#define LOCALHOST "127."

// FIXME this SHOULD be in net/if.h, but doesn't get included for some insane reason
#ifndef IFF_LOOPBACK
#define IFF_LOOPBACK 0 // skip if undefined
#endif

// hope they don't do something weird lol
SEXP pbdcs_getip_nix()
{
  SEXP ip;
  struct ifaddrs *tmp, *ifap;
  struct sockaddr_in *pAddr;
  char *addr;
  
  getifaddrs(&ifap);
  tmp = ifap;
  
  while (tmp)
  {
    if (tmp->ifa_addr && tmp->ifa_addr->sa_family == AF_INET)
    {
      pAddr = (struct sockaddr_in *) tmp->ifa_addr;
      
      addr = inet_ntoa(pAddr->sin_addr);
      
      if (strncmp(tmp->ifa_name, "lo", 2) != 0  && 
          strncmp(addr, LOCALHOST, 4)     != 0  && 
          !(tmp->ifa_flags & IFF_LOOPBACK)  )
      {
        PROTECT(ip = allocVector(STRSXP, 1));
        SET_STRING_ELT(ip, 0, mkChar(addr));
        free(ifap);
        UNPROTECT(1);
        return ip;
      }
    }
    
    tmp = tmp->ifa_next;
  }
  
  freeifaddrs(ifap);
  
  return R_NilValue;
}
#endif



SEXP pbdcs_getip()
{
  SEXP ret;
  #if OS_WINDOWS
  ret = R_NilValue; // TODO
  #else
  ret = pbdcs_getip_nix();
  #endif
  
  return ret;
}
