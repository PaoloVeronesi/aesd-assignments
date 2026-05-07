#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <syslog.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdbool.h>

#define PORT 9000
#define DATA_FILE "/var/tmp/aesdsocketdata"

volatile sig_atomic_t caught_signal = 0;

void signal_handler(int sig) {
    caught_signal = 1;
}

int main(int argc, char* argv[]) {

    bool is_daemon = false;
    if (argc > 1 && strcmp(argv[1], "-d") == 0) {
        is_daemon = true;
    }
    openlog("aesdsocket", LOG_PID, LOG_USER);

    int server_fd;
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        return -1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        return -1;
    }

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);
    if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
        return -1;
    }

    if (listen(server_fd, 10) < 0) {
        return -1;
    }

    if (is_daemon) {
        pid_t pid = fork();
        if (pid < 0) {
            return -1;
        }
        if (pid > 0) {
            exit(0);
        }
        setsid();
        chdir("/");
        close(STDIN_FILENO);
        close(STDOUT_FILENO);
        close(STDERR_FILENO);
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

    struct sockaddr_in client_addr;
    socklen_t client_len;
    int client_fd;

    while (!caught_signal) {
        client_len = sizeof(client_addr);
        client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);

        if (client_fd < 0) {
            if (caught_signal) break;
            continue;
        }

        char *client_ip = inet_ntoa(client_addr.sin_addr);
        syslog(LOG_INFO, "Accepted connection from %s", client_ip);

        // Ricevi dati fino a newline - buffer dinamico
        char *recv_buffer = NULL;
        size_t recv_size = 0;
        char temp_buffer[1024];
        ssize_t bytes_recv;

        while ((bytes_recv = recv(client_fd, temp_buffer, sizeof(temp_buffer), 0)) > 0) {
            char *new_buffer = realloc(recv_buffer, recv_size + bytes_recv);
            if (new_buffer == NULL) {
                free(recv_buffer);
                syslog(LOG_ERR, "realloc failed");
                break;
            }
            recv_buffer = new_buffer;
            memcpy(recv_buffer + recv_size, temp_buffer, bytes_recv);
            recv_size += bytes_recv;

            if (memchr(temp_buffer, '\n', bytes_recv) != NULL) {
                break;
            }
        }

        // Scrivi nel file
        if (recv_buffer != NULL && recv_size > 0) {
            int file_fd = open(DATA_FILE, O_CREAT | O_APPEND | O_WRONLY, 0644);
            write(file_fd, recv_buffer, recv_size);
            close(file_fd);
            free(recv_buffer);
        }

        // Invia tutto il contenuto del file al client
        int file_fd = open(DATA_FILE, O_RDONLY);
        char buffer[1024];
        while ((bytes_recv = read(file_fd, buffer, sizeof(buffer))) > 0) {
            send(client_fd, buffer, bytes_recv, 0);
        }
        close(file_fd);

        syslog(LOG_INFO, "Closed connection from %s", client_ip);
        close(client_fd);
    }

    syslog(LOG_INFO, "Caught signal, exiting");
    close(server_fd);
    unlink(DATA_FILE);
    closelog();

    return 0;
}