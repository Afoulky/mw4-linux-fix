/*
 * mw4-net.so: lets the game download its HD textures without IPv6.
 *
 * The game looks up the texture CDN for IPv6 only. Without IPv6, the answer
 * is an IPv4 address written as ::ffff:a.b.c.d, and Wine, like Windows,
 * creates IPv6 sockets with IPV6_V6ONLY set, so connect() to that address
 * fails and no texture is ever downloaded. When a connect() targets such an
 * address on a V6ONLY socket, this clears IPV6_V6ONLY first, so the
 * connection goes out over IPv4. Every other connect() is left as it is.
 *
 * Loaded through LD_PRELOAD by mw4-launch (Wine connects sockets from the
 * wineserver process). It only uses symbols every glibc has, and calls the
 * connect system call directly, so it works inside any Steam Runtime.
 *
 * Build: gcc -O2 -shared -fPIC -fno-stack-protector -o bin/mw4-net.so source/mw4-net.c
 */
#define _GNU_SOURCE
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <unistd.h>

int connect(int fd, const struct sockaddr *addr, socklen_t len)
{
    if (addr && addr->sa_family == AF_INET6 && len >= sizeof(struct sockaddr_in6))
    {
        const struct sockaddr_in6 *in6 = (const struct sockaddr_in6 *)addr;
        int v6only = 0;
        socklen_t size = sizeof(v6only);

        if (IN6_IS_ADDR_V4MAPPED(&in6->sin6_addr)
                && getsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &v6only, &size) == 0 && v6only)
        {
            v6only = 0;
            setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &v6only, sizeof(v6only));
        }
    }
    return syscall(SYS_connect, fd, addr, len);
}
