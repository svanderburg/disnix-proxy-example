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

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <netdb.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <arpa/inet.h>

#define BUFFER_SIZE 4096
#define TRUE 1
#define FALSE 0

int num_of_connections = 0;

static void print_usage()
{
    printf("Usage:\n");
    printf("disnix-proxy source_port destination_hostname destination_port lock_filename\n");
}

static void set_nonblock(int sockfd)
{
    int fl;
    
    /* Get the file status flags */
    if((fl = fcntl(sockfd, F_GETFL, 0)) < 0)
    {
	fprintf(stderr, "Error getting filestatus flags: %s\n", strerror(errno));
	_exit(1);
    }
    
    /* Set the file status flags on non-blocking */
    if(fcntl(sockfd, F_SETFL, fl | O_NONBLOCK) < 0)
    {
	fprintf(stderr, "Error setting filestatus flags: %s\n", strerror(errno));
	_exit(1);
    }    
}

static int create_server_socket(int source_port)
{
    int sockfd, on = 1;
    struct sockaddr_in client_addr;
    
    /* Create socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if(sockfd < 0)
	fprintf(stderr, "Error creating server socket\n");

    /* Create address struct */
    memset(&client_addr, '\0', sizeof(client_addr));
    client_addr.sin_family = AF_INET;
    client_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    client_addr.sin_port = htons(source_port);
    
    /* Set socket options to reuse the address */
    setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, 4);
    
    /* Bind the name (ip address) to the socket */
    if(bind(sockfd, (struct sockaddr *)&client_addr, sizeof(client_addr)) < 0)
	fprintf(stderr, "Error binding to port: %d, %s\n", source_port, strerror(errno));
    
    /* Listen for connections on the socket */
    if(listen(sockfd, 5) < 0)
	fprintf(stderr, "Error listening on port: %d\n", source_port);

    /* Return the socket filedescriptor */
    return sockfd;
}

static int create_admin_socket(char *socket_path)
{
    int sockfd;
    struct sockaddr_un client_addr;
    
    /* Create socket */
    sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if(sockfd < 0)
	fprintf(stderr, "Error creating admin socket\n");

    /* Create address struct */
    memset(&client_addr, '\0', sizeof(client_addr));
    client_addr.sun_family = AF_UNIX;
    strcpy(client_addr.sun_path, socket_path);
        
    /* Bind the name (ip address) to the socket */
    unlink(socket_path);
    
    if(bind(sockfd, (struct sockaddr *)&client_addr, sizeof(client_addr)) < 0)
	fprintf(stderr, "Error binding: %s: %s\n", socket_path, strerror(errno));
    
    /* Listen for connections on the socket */
    if(listen(sockfd, 5) < 0)
	fprintf(stderr, "Error listening on %s\n", socket_path);

    /* Return the socket filedescriptor */
    return sockfd;
}

static int wait_for_connection(int server_sockfd)
{
    int client_sockfd, len;
    struct sockaddr_in peer;
    
    /* Accept client connection and create client socket */
    len = sizeof(struct sockaddr);
    
    if((client_sockfd = accept(server_sockfd, (struct sockaddr *)&peer, &len)) < 0)
    {
	if(errno == EAGAIN || errno == EWOULDBLOCK)
	    return -1; /* Stop annoying messages */
	else if(errno != EINTR)
	{
	    fprintf(stderr, "Error creating client socket: %s\n", strerror(errno));
	    return -1;
	}
    }
    
    /* Set socket on non blocking mode */
    set_nonblock(client_sockfd);

    /* Return the socket filedescriptor */
    return client_sockfd;
}

static int open_remote_host(char *host, int port)
{
    struct hostent *hostinfo;
    int target_sockfd;
    int on = 1;
    struct sockaddr_in target_addr;
    
    /* Get hostname */
    if(!(hostinfo = gethostbyname(host)))
	return -2;
    
    /* Create socket to target remote host */
    if((target_sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
	return target_sockfd;
    
    /* Set socket options to reuse the address */
    setsockopt(target_sockfd, SOL_SOCKET, SO_REUSEADDR, &on, 4);
    
    /* Create the address struct */    
    memset(&target_addr, '\0', sizeof(target_addr));
    target_addr.sin_family = AF_INET;
    memcpy(&target_addr.sin_addr, hostinfo->h_addr, hostinfo->h_length);
    target_addr.sin_port = htons(port);
    
    /* Connect to the remote host */
    if(connect(target_sockfd, (struct sockaddr *)&target_addr, sizeof(target_addr)) < 0)
    {
	close(target_sockfd);
	return -1;
    }
    
    /* Set socket on non blocking mode */
    set_nonblock(target_sockfd);

    /* Return the socket filedescriptor */
    return target_sockfd;    
}

static int mywrite(int fd, char *buf, int *len)
{
    /* Write the bytes to the file descriptor */
    int num_of_written_bytes = write(fd, buf, *len);
    
    /* If no bytes are written or an error occurs, return the result */
    if(num_of_written_bytes <= 0)
	return num_of_written_bytes;

    /* If not all bytes are written, create a new buffer with the unwritten bytes */
    if(num_of_written_bytes != *len)
	memmove(buf, buf+num_of_written_bytes, (*len)-num_of_written_bytes);

    /* Decrease the length with number of written bytes (should be 0 if all bytes are written) */
    *len -= num_of_written_bytes;
    
    /* Return number of written bytes */
    return num_of_written_bytes;
}

static void do_proxy(int client_sockfd, int target_sockfd)
{
    int maxfd;
    char *client_buffer, *target_buffer;
    int client_buffer_offset = 0, target_buffer_offset = 0;
    int num_of_fds, n;
    fd_set fds;
    
    /* Get memory for buffers */
    client_buffer = (char*)malloc(BUFFER_SIZE);
    target_buffer = (char*)malloc(BUFFER_SIZE);
    
    /* Get highest filedescriptor value */
    maxfd = client_sockfd > target_sockfd ? client_sockfd : target_sockfd;
    maxfd++;

    /* Keep sending all incoming data from client to target */
    
    while(TRUE)
    {
	struct timeval to;
		
	/* Write everything in the client buffer to the target socket */
	if(client_buffer_offset > 0)
	{
	    if(mywrite(target_sockfd, client_buffer, &client_buffer_offset) < 0 && errno != EWOULDBLOCK)
	    {
		fprintf(stderr, "Error writing to target socket: %s\n", strerror(errno));
		_exit(1);
	    }
	}
	
	/* Write everything in the target buffer to the client socket */
	if(target_buffer_offset > 0)
	{
	    if(mywrite(client_sockfd, target_buffer, &target_buffer_offset) < 0 && errno != EWOULDBLOCK)
	    {
		fprintf(stderr, "Error writing to client socket: %s\n", strerror(errno));
		_exit(1);
	    }
	}
	
	/* Clear the filedescriptor set */
	FD_ZERO(&fds);
	
	/* Add buffers to filedescriptor set if they are not full yet */
	if(client_buffer_offset < BUFFER_SIZE)
	    FD_SET(client_sockfd, &fds);
	if(target_buffer_offset < BUFFER_SIZE)
	    FD_SET(target_sockfd, &fds);
	
	/* Set the monitor timeout */
	to.tv_sec = 0;
	to.tv_usec = 1000;
	
	/* Monitor the filedescriptors in the set */
	num_of_fds = select(maxfd+1, &fds, 0, 0, &to);
	
	if(num_of_fds > 0)
	{
	    if(FD_ISSET(client_sockfd, &fds))
	    {
		/* Read bytes from client socket */		
		n = read(client_sockfd, client_buffer+client_buffer_offset, BUFFER_SIZE - client_buffer_offset);
		
		if(n > 0)
		    client_buffer_offset += n;
		else
		{
		    close(client_sockfd);
		    close(target_sockfd);
		    _exit(0);
		}
	    }
	    
	    if(FD_ISSET(target_sockfd, &fds))
	    {
		/* Read bytes from target socket */		
		n = read(target_sockfd, target_buffer+target_buffer_offset, BUFFER_SIZE - target_buffer_offset);
		
		if(n > 0)
		    target_buffer_offset += n;
		else
		{
		    close(target_sockfd);
		    close(client_sockfd);
		    _exit(0);
		}
	    }
	}
	else if(num_of_fds < 0 && errno != EINTR)
	{
	    fprintf(stderr, "Error with select: %s\n", strerror(errno));
	    close(target_sockfd);
	    close(client_sockfd);
	}
    }
}

static int is_blocking(char *lock_filename)
{
    int fd = open(lock_filename, O_RDONLY);
    
    if(fd == -1)
	return FALSE;
    else
    {
	close(fd);
	return TRUE;
    }
}

void cleanup(int signal)
{
    printf("Cleaning up...\n");
    _exit(0);
}

void sigreap(int sig)
{
    pid_t pid;
    int status;
    num_of_connections--;
    
    signal(SIGCHLD, sigreap); /* Event handler when a child terminates */
    
    while((pid = waitpid(-1, &status, WNOHANG)) > 0); /* Wait until all child processes terminate */
}

int main(int argc, char *argv[])
{
    int source_port;
    char *destination_address;
    int destination_port;
    int server_sockfd = -1, client_sockfd = -1, target_sockfd = -1, admin_sockfd = -1, admin_client_sockfd = -1;
    char *lock_filename;
    
    /* Check parameters */
    
    if(argc != 5)
    {
	print_usage();
	_exit(1);
    }
    
    /* Get parameter values */
    source_port = atoi(argv[1]);
    destination_address = strdup(argv[2]);
    destination_port = atoi(argv[3]);
    lock_filename = strdup(argv[4]);
    
    /* Create signal handlers */
    signal(SIGINT, cleanup); /* Event handler for interruption */
    signal(SIGCHLD, sigreap); /* Event handler when a child terminates */
    
    /* Create server socket */
    server_sockfd = create_server_socket(source_port);
    set_nonblock(server_sockfd);
    
    /* Create admin socket */
    admin_sockfd = create_admin_socket("/tmp/disnix-tcp-proxy.sock");
    set_nonblock(admin_sockfd);
    
    /* Main loop */ 
       
    while(TRUE)
    {
	int status;
	
	/* Create admin client socket if there is an incoming connection */
	if((admin_client_sockfd = wait_for_connection(admin_sockfd)) >= 0)
	{
	    char msg[BUFFER_SIZE];
		
	    printf("Admin connection from client\n");
		
	    sprintf(msg, "%d", num_of_connections);
	    if(send(admin_client_sockfd, msg, strlen(msg), 0) < 0)
	        fprintf(stderr, "Error sending message to admin client: %s\n", strerror(errno));
		
	    close(admin_client_sockfd);
	    admin_client_sockfd = -1;    
	}
    
	/* If we want to block do not accept any incoming client connections */
        if(is_blocking(lock_filename))
	    continue;
	    
	/* Create client if there is an incoming connection */
	if((client_sockfd = wait_for_connection(server_sockfd)) < 0)
	    continue;
	    
	/* Connect to the remote host */
	if((target_sockfd = open_remote_host(destination_address, destination_port)) < 0)
	{
	    close(client_sockfd);
	    client_sockfd = -1;
	    continue;
	}
	
	/* Fork a new process for each incoming client */
	status = fork();
	    
	if(status == 0)
	{
	    printf("Connection from client\n");
	    close(server_sockfd);
	    close(admin_sockfd);
	    do_proxy(client_sockfd, target_sockfd);
	    abort();
	}
	else if(status == -1)
	    fprintf(stderr, "Error in forking process\n");
	else
	    num_of_connections++;
	    
	/* Close the connections to the remote host and client */
	close(client_sockfd);
	client_sockfd = -1;
	close(target_sockfd);
	target_sockfd = -1;
    }
    
    return 0;
}
