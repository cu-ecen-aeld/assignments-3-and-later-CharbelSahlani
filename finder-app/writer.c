/*
 * C file to create a file in a specified directory and write to it a specific string using SYS_LOG
 * Author: Charbel Al Sahlani
 */ 


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

int main(int argc, char *argv[]) 
{
    // Open connection to system logger
    // LOG_PID includes the process ID with each message
    // LOG_USER is the standard facility for user-level programs
    openlog("FileWriterProgram", LOG_PID, LOG_USER);

    // Error Check: Verify both arguments are provided
    if (argc < 3) 
    {
        syslog(LOG_ERR, "Error: Missing arguments. Usage: %s <file_path> <string_to_write>", argv[0]);
        fprintf(stderr, "Error: Missing arguments. Check system logs for details.\n");
        closelog();
        return EXIT_FAILURE;
    }

    char *file_path = argv[1];
    char *text_to_write = argv[2];

    // Attempt to open the target file for writing ("w" overwrites, "a" appends)
    syslog(LOG_DEBUG , "Attempting to open file '%s'", file_path);
    FILE *file = fopen(file_path, "w");
    if (file == NULL) 
    {
        // LOG_ERR captures the exact system reason (e.g., Permission denied, No such file)
        syslog(LOG_ERR, "Error opening file '%s': %s", file_path, strerror(errno));
        fprintf(stderr, "Error: Failed to open file. Check system logs for details.\n");
        closelog();
        return EXIT_FAILURE;
    }

    // Write the string to the file
    syslog(LOG_DEBUG , "Attempting to write string %s to file '%s'", text_to_write, file_path);
    if (fputs(text_to_write, file) == EOF) 
    {
        syslog(LOG_ERR, "Error writing data to file '%s': %s", file_path, strerror(errno));
        fprintf(stderr, "Error: Failed to write to file. Check system logs for details.\n");
        fclose(file);
        closelog();
        return EXIT_FAILURE;
    }

    // Success log and cleanup
    fclose(file);
    syslog(LOG_DEBUG, "Successfully wrote %s to file: '%s'", text_to_write, file_path);
    closelog();

    return EXIT_SUCCESS;
}
