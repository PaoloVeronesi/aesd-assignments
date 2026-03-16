#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <file> <string>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *filename = argv[1];
    const char *text = argv[2];

    // Open syslog
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    FILE *fp = fopen(filename, "w");
    if (!fp) {
        syslog(LOG_ERR, "Failed to open file '%s': %s", filename, strerror(errno));
        fprintf(stderr, "Error opening file '%s': %s\n", filename, strerror(errno));
        closelog();
        exit(EXIT_FAILURE);
    }

    if (fputs(text, fp) == EOF) {
        syslog(LOG_ERR, "Failed to write to file '%s': %s", filename, strerror(errno));
        fprintf(stderr, "Error writing to file '%s': %s\n", filename, strerror(errno));
        fclose(fp);
        closelog();
        exit(EXIT_FAILURE);
    }

    syslog(LOG_DEBUG, "Writing '%s' to '%s'", text, filename);


    if (fclose(fp) == EOF) {
        syslog(LOG_ERR, "Failed to close file '%s': %s", filename, strerror(errno));
        fprintf(stderr, "Error closing file '%s': %s\n", filename, strerror(errno));
        closelog();
        exit(EXIT_FAILURE);
    }

    // Log success message
    syslog(LOG_DEBUG, "Writing '%s' to '%s'", text, filename);

    closelog();
    return EXIT_SUCCESS;
}