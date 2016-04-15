#include <stddef.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "elfhook.h"

#include "EVAPI.h"
#include "CoroAPI.h"


#define DEBUG 1

#ifdef DEBUG
#define debug(...) \
  do { \
  time_t now = time(NULL); \
  char t[30]; \
  ctime_r(&now, t); \
  t[24] = '\0'; \
  fprintf(stderr, "[Elfhook.xs] [%s] [%d] ", t, getpid()); \
  fprintf(stderr, __VA_ARGS__); \
  } while(0);
#else  /* #define DEBUG */
#define debug(...)
#endif /* #define DEBUG */


static void
restore_flags(int fd, int flags)
{
  fcntl(fd, F_SETFL, flags);
}


static int
setNonblock(int fd, int* oldFlags)
{
  *oldFlags = fcntl(fd, F_GETFL, 0);
  if ((*oldFlags) & O_NONBLOCK) {
    return 0;
  };
  fcntl(fd, F_SETFL, *oldFlags | O_NONBLOCK);
  return 1;
}


ssize_t
our_read(int fd, void* buf, size_t nbyte)
{
  int flags, s_err;
  ssize_t retval;

  debug("Enter our_read.\n");

  if (!GCoroAPI || !setNonblock(fd, &flags)) {
    debug("read fallback.\n");
    return read(fd, buf, nbyte);
  }

  do {
    retval = read(fd, buf, nbyte);
    s_err = errno;
    if (retval < 0 && (s_err == EWOULDBLOCK || s_err == EAGAIN)) {
      CORO_CEDE; // yield next coro from ready queue.
    }
    // retval >= 0: Success.
    // retval < 0 && errno != EWOULDBLOCK || s_err == EAGAIN: cannot recover.
    else {
      break;
    }
  } while (1);

  restore_flags(fd, flags);
  errno = s_err;
  return retval;
}


ssize_t
our_write(int fd, void* buf, size_t nbyte)
{
  int flags, s_err;
  ssize_t retval;

  debug("Enter our_write.\n");

  if (!GCoroAPI || !setNonblock(fd, &flags)) {
    debug("write fallback.\n");
    return write(fd, buf, nbyte);
  }

  do {
    retval = write(fd, buf, nbyte);
    s_err = errno;
    if (retval < 0 && (s_err == EWOULDBLOCK || s_err == EAGAIN)) {
      CORO_CEDE; // yield next coro from ready queue.
    }
    // retval >= 0: Success.
    // retval < 0 && errno != EWOULDBLOCK || s_err == EAGAIN: cannot recover.
    else {
      break;
    }
  } while (1);

  restore_flags(fd, flags);
  errno = s_err;
  return retval;
}


ssize_t
our_recv(int fd, void* buf, size_t nbyte, int flags)
{
  int sock_flags, s_err;
  ssize_t retval;

  debug("Enter our_recv.\n");

  if (!GCoroAPI || !setNonblock(fd, &sock_flags)) {
    return recv(fd, buf, nbyte, flags);
  }

  do {
    retval = recv(fd, buf, nbyte, flags);
    s_err = errno;
    if (retval < 0 && (s_err == EWOULDBLOCK || s_err == EAGAIN)) {
      CORO_CEDE; // yield next coro from ready queue.
    }
    // retval >= 0: Success.
    // retval < 0 && errno != EWOULDBLOCK || s_err == EAGAIN: cannot recover.
    else {
      break;
    }
  } while (1);

  restore_flags(fd, sock_flags);
  errno = s_err;
  return retval;
}


ssize_t
our_send(int fd, void* buf, size_t nbyte, int flags)
{
  int sock_flags, s_err;
  ssize_t retval;

  debug("Enter our_send.\n");

  if (!GCoroAPI || !setNonblock(fd, &sock_flags)) {
    return send(fd, buf, nbyte, flags);
  }

  do {
    retval = send(fd, buf, nbyte, flags);
    s_err = errno;
    if (retval < 0 && (s_err == EWOULDBLOCK || s_err == EAGAIN)) {
      CORO_CEDE; // yield next coro from ready queue.
    }
    // retval >= 0: Success.
    // retval < 0 && errno != EWOULDBLOCK || s_err == EAGAIN: cannot recover.
    else {
      break;
    }
  } while (1);

  restore_flags(fd, sock_flags);
  errno = s_err;
  return retval;
}


ssize_t
our_recvmsg(int fd, struct msghdr* message, int flags)
{
  int sock_flags, s_err;
  ssize_t retval;

  debug("Enter our_recvmsg.\n");

  if (!GCoroAPI || !setNonblock(fd, &sock_flags)) {
    return recvmsg(fd, message, flags);
  }

  do {
    retval = recvmsg(fd, message, flags);
    s_err = errno;
    if (retval < 0 && (s_err == EWOULDBLOCK || s_err == EAGAIN)) {
      CORO_CEDE; // yield next coro from ready queue.
    }
    // retval >= 0: Success.
    // retval < 0 && errno != EWOULDBLOCK || s_err == EAGAIN: cannot recover.
    else {
      break;
    }
  } while (1);

  restore_flags(fd, sock_flags);
  errno = s_err;
  return retval;
}


int
patchLibrary(const char* name)
{
  I_CORO_API("Elfhook");

  int result = 0;
  if (hook(name, "read", &our_read) != NULL) {
    result = 1;
  };
  if (hook(name, "write", &our_write) != NULL) {
    result = 1;
  };
  if (hook(name, "recv", &our_recv) != NULL) {
    result = 1;
  };
  if (hook(name, "send", &our_send) != NULL) {
    result = 1;
  };
  if (hook(name, "recvmsg", &our_recvmsg) != NULL) {
    result = 1;
  };
  return result;
}


MODULE = Elfhook          PACKAGE = Elfhook

void
patch(...)
  PPCODE:
{
  SV* item = ST(0);
  const char* library = SvPV_nolen(item);
  int ret = patchLibrary(library);

  XPUSHs(sv_2mortal(newSViv(ret)));
  XSRETURN(1);
}
