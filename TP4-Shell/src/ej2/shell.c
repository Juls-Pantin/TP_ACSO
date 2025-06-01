#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <ctype.h>
#define MAX_COMMANDS 200
void free_args(char **args, int count) {
    for (int i = 0; i < count; i++) {
        if (args[i]) free(args[i]);
    }
}

int main() {

    setbuf(stdout, NULL);

    char command[256];
    char *commands[MAX_COMMANDS];
    int command_count = 0;

    while (1) 
    {
        printf("Shell> ");

        if (fgets(command, sizeof(command), stdin) == NULL) {
            break;
        }

        for (char *p = command; *p != '\0'; p++) {
            if (*p == '\t') *p = ' ';
        }
        
        /* Removes the newline character (\n) from the end of the string stored in command, if present. 
           This is done by replacing the newline character with the null character ('\0').
           The strcspn() function returns the length of the initial segment of command that consists of 
           characters not in the string specified in the second argument ("\n" in this case). */
        command[strcspn(command, "\n")] = '\0';

        /* Tokenizes the command string using the pipe character (|) as a delimiter using the strtok() function. 
           Each resulting token is stored in the commands[] array. 
           The strtok() function breaks the command string into tokens (substrings) separated by the pipe character |. 
           In each iteration of the while loop, strtok() returns the next token found in command. 
           The tokens are stored in the commands[] array, and command_count is incremented to keep track of the number of tokens found. */
        command_count = 0;
        memset(commands, 0, sizeof(commands));
        char *token = strtok(command, "|");
        while (token != NULL) 
        {
            commands[command_count++] = token;
            token = strtok(NULL, "|");
        }

        if (command_count > 0 && strcmp(commands[0], "exit") == 0 && command_count == 1) {
            exit(0);
        }

        for (int i = 0; i < command_count; i++) {
            if (commands[i] == NULL || strlen(commands[i]) == 0) {
                fprintf(stderr, "Comando vacío o inválido\n");
                command_count = 0;
                break;
            }
        }

        /* aca empieza mi codigo :) */
        if (command_count == 0) {
            continue;
        }
        int pipefd[2 * (command_count - 1)];
        for (int i = 0; i < command_count - 1; i++) {
            if (pipe(pipefd + i*2) < 0) {
                perror("pipe");
                exit(EXIT_FAILURE);
            }
        }

        for (int i = 0; i < command_count; i++) {
            pid_t pid = fork();
            if (pid == 0) {
                fflush(stdout); fflush(stderr);
                if (i > 0) {
                    if (dup2(pipefd[(i - 1) * 2], STDIN_FILENO) < 0) {
                        perror("dup2 stdin");
                        exit(EXIT_FAILURE);
                    }
                }
                if (i < command_count - 1) {
                    if (dup2(pipefd[i * 2 + 1], STDOUT_FILENO) < 0) {
                        perror("dup2 stdout");
                        exit(EXIT_FAILURE);
                    }
                }
                // cierro todos los pipes
                for (int j = 0; j < 2 * (command_count - 1); j++) {
                    close(pipefd[j]);
                }

                // nuevo parseo con malloc y manejo de comillas
                char *args[64];
                int arg_count = 0;
                char *cmd = commands[i];
                while (*cmd != '\0') {
                    while (*cmd == ' ' || *cmd == '\t') cmd++;
                    if (*cmd == '\0') break;

                    if (*cmd == '\"') {
                        cmd++;
                        char *start = cmd;
                        while (*cmd && *cmd != '\"') cmd++;
                        if (*cmd != '\"') {
                            fprintf(stderr, "Error: comillas sin cerrar\n");
                            free_args(args, arg_count);
                            exit(EXIT_FAILURE);
                        }
                        size_t len = cmd - start;
                        args[arg_count] = malloc(len + 1);
                        strncpy(args[arg_count], start, len);
                        args[arg_count][len] = '\0';
                        arg_count++;
                        cmd++;  // saltar cierre de comillas
                    } else {
                        char *start = cmd;
                        while (*cmd && *cmd != ' ' && *cmd != '\t') cmd++;
                        size_t len = cmd - start;
                        args[arg_count] = malloc(len + 1);
                        strncpy(args[arg_count], start, len);
                        args[arg_count][len] = '\0';
                        arg_count++;
                    }
                }
                args[arg_count] = NULL;

                if (arg_count >= 64) {
                    fprintf(stderr, "Error: demasiados argumentos\n");
                    free_args(args, arg_count);
                    exit(EXIT_FAILURE);
                }

                if (arg_count == 0 || args[0][0] == '\0') {
                    fprintf(stderr, "Comando vacío o inválido\n");
                    free_args(args, arg_count);
                    exit(EXIT_FAILURE);
                }

                execvp(args[0], args);
                fprintf(stderr, "Error: no se pudo ejecutar el comando '%s'\n", args[0]);
                perror("execvp");
                for (int j = 0; j < arg_count; j++) {
                    if (args[j]) free(args[j]);
                }
                exit(EXIT_FAILURE);
            }
        }

        // padre -> cierro todos los pipes
        for (int i = 0; i < 2 * (command_count - 1); i++) {
            close(pipefd[i]);
        }
        // espero a que todos los hijos terminen
        for (int i = 0; i < command_count; i++) {
            wait(NULL);
        }

        for (int i = 0; i < command_count; i++) {
            // commands[i] apunta a 'command' original, no hay que liberar
        }

        fflush(stdout);
        fflush(stderr);

        // reseteo el contador de comandos
        command_count = 0;
        memset(commands, 0, sizeof(commands));
    }
    return 0;
}
