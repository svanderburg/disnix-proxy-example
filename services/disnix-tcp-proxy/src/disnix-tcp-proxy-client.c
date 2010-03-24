/*
 * Copyright (c) 2008-2010 Sander van der Burg
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#define BUFFER_SIZE 1024

int main(int argc, char *argv[])
{
    struct sockaddr_un server_addr;
    int sockfd;
    char *socket_path = "/tmp/disnix-tcp-proxy.sock";
    char line[BUFFER_SIZE];
    ssize_t line_size;
    
    /* Create socket */
    sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
    
    if(sockfd < 0)
	fprintf(stderr, "Error creating socket\n");
    
    /* Create address struct */
    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sun_family = AF_UNIX;
    strcpy(server_addr.sun_path, socket_path);

    /* Create connection */
    if(connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
	fprintf(stderr, "Error connecting to TCP proxy: %s\n", strerror(errno));
    
    /* Retrieve result */
    while((line_size = recv(sockfd, line, BUFFER_SIZE - 1, 0)) > 0)
    {
	line[line_size] = '\0';
	printf("%s\n", line);
    }
    
    /* Close connection */
    close(sockfd);
    
    return 0;
}
