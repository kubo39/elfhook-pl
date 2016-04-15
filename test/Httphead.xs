#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int
c_http_head(const char *host, const char* port)
{
  struct addrinfo *p, hints, *res;
  char request[64];
  char response[2049];
  int socket_fd;

  sprintf(request, "HEAD / HTTP/1.1\nhost: %s\n\n", host);

  memset(&hints, 0, sizeof(hints));

  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  getaddrinfo(host, port, &hints, &res);
  for (p = res; p; p = p->ai_next) {
    socket_fd = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
    if (connect(socket_fd, p->ai_addr, p->ai_addrlen) == 0) {
      break;
    }
  }

  write(socket_fd, request, strlen(request));
  read(socket_fd, response, 2048);
  close(socket_fd);

  if (strstr(response, "HTTP/1.") != NULL) {  // HTTP/1.1 or HTTP/1.0
    return 1;
  }
  else {
    fprintf(stderr, "[%s] unexpected response: %s\n", __FUNCTION__, response);
  }
  return 0;
}

MODULE = Httphead    PACKAGE = Httphead

void
http_head(...)
  PPCODE:
{
  SV* sv_host = ST(0);
  SV* sv_port = ST(1);
  const char* host = SvPV_nolen(sv_host);
  const char* port  = SvPV_nolen(sv_port);
  printf("host: %s\n", host);
  printf("port: %s\n", port);
  int ret = c_http_head(host, port);
  XPUSHs(sv_2mortal(newSViv(ret)));
  XSRETURN(1);
}
