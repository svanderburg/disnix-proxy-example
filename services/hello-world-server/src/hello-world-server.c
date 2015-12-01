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
 
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef SYSTEMD_SOCKET_ACTIVATION
#include <systemd/sd-daemon.h>
#endif

#define TRUE 1
#define FALSE 0
#define BUFFER_SIZE 1024

#ifdef SELF_TERMINATION
#include <signal.h>
#include <sys/wait.h>

/* Counts the amount of open connections */
volatile unsigned int num_of_connections = 0;

void sigreap(int sig)
{
    pid_t pid;
    int status;
    num_of_connections--;
    
    signal(SIGCHLD, sigreap); /* Event handler when a child terminates */
    
    while((pid = waitpid(-1, &status, WNOHANG)) > 0); /* Wait until all child processes terminate */
    
    /* If there are no open connections => self terminate */
    if(num_of_connections == 0)
        _exit(0);
}
#endif

static void print_usage()
{
    printf("Usage:\n");
    printf("hello-world-server port\n");
}

static int create_server_socket(int source_port)
{
    int sockfd, on = 1;

#ifdef SYSTEMD_SOCKET_ACTIVATION
    int n = sd_listen_fds(0);
    
    if(n > 1)
    {
        fprintf(stderr, "Too many file descriptors received!\n");
        return -1;
    }
    else if(n == 1)
        sockfd = SD_LISTEN_FDS_START + 0;
    else
    {
#endif
        struct sockaddr_in client_addr;
        
        /* Create socket */
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if(sockfd < 0)
            fprintf(stderr, "Error creating server socket!\n");
        
        /* Create address struct */
        memset(&client_addr, '\0', sizeof(client_addr));
        client_addr.sin_family = AF_INET;
        client_addr.sin_addr.s_addr = htonl(INADDR_ANY);
        client_addr.sin_port = htons(source_port);
        
        /* Set socket options to reuse the address */
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, 4);
        
        /* Bind the name (ip address) to the socket */
        if(bind(sockfd, (struct sockaddr *)&client_addr, sizeof(client_addr)) < 0)
            fprintf(stderr, "Error binding on port: %d, %s\n", source_port, strerror(errno));
        
        /* Listen for connections on the socket */
        if(listen(sockfd, 5) < 0)
            fprintf(stderr, "Error listening on port %d\n", source_port);

#ifdef SYSTEMD_SOCKET_ACTIVATION
    }
#endif

    /* Return the socket file descriptor */
    return sockfd;
}

static int wait_for_connection(int server_sockfd)
{
    int client_sockfd, len;
    struct sockaddr_in peer;
    
    printf("Accepting connection\n");
    
    /* Accept client connection and create client socket */
    len = sizeof(struct sockaddr);
    
    if((client_sockfd = accept(server_sockfd, (struct sockaddr *)&peer, &len)) < 0)
    {
	if(errno != EINTR)
	{
	    fprintf(stderr, "Error creating client socket: %s\n", strerror(errno));
	    return -1;
	}
    }
    
    /* Return the socket filedescriptor */
    return client_sockfd;
}

int main(int argc, char *argv[])
{
    int server_sockfd = -1, client_sockfd = -1;
    int source_port;
    
    if(argc != 2)
    {
	print_usage();
	return 1;
    }
    
    /* Assign command-line arguments */
    source_port = atoi(argv[1]);
    
    /* Create server socket */
    server_sockfd = create_server_socket(source_port);
    
#ifdef SELF_TERMINATION
    signal(SIGCHLD, sigreap); /* Event handler when a child terminates */
#endif

    while(TRUE)
    {
	/* Create client socket if there is an incoming connection */
	if((client_sockfd = wait_for_connection(server_sockfd)) >= 0)
	{
	    /* Fork a new process for each incoming client */
	    pid_t pid = fork();
	    
	    if(pid == 0)
	    {
		char line[BUFFER_SIZE];
		ssize_t line_size;
		
		printf("Connection from client\n");
		close(server_sockfd);
		
		while((line_size = recv(client_sockfd, line, BUFFER_SIZE - 1, 0)) > 0)
		{
		    line[line_size] = '\0';
		    printf("Received: %s\n", line);
		    
		    if(strcmp(line, "quit\r\n") == 0)
			break;
		    else if(strcmp(line, "hello\r\n") == 0)
			send(client_sockfd, "Hello world!\r\n", 14, 0);
		}
		
		close(client_sockfd);
		_exit(0);
	    }
	    else if(pid == -1)
	        fprintf(stderr, "Cannot fork connection handling process!\n");
#ifdef SELF_TERMINATION
	    else
	        num_of_connections++;
#endif
	}
	
	close(client_sockfd);
	client_sockfd = -1;
    }
    /* Extra stuff */
    return 0;
}
