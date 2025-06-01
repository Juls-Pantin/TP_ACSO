#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Uso: anillo <n> <c> <s>\n");
        return EXIT_FAILURE;
    }

    int n = atoi(argv[1]);
    int valor = atoi(argv[2]);
    int inicio = atoi(argv[3]);

    if (n < 3 || inicio < 0 || inicio >= n) {
        fprintf(stderr, "Parámetros inválidos: n >= 3, 0 <= inicio < n\n");
        return EXIT_FAILURE;
    }

    printf("Se crearán %d procesos, se enviará el caracter %d desde proceso %d (índice 0)\n", n, valor, inicio);

    int anillo[n][2];
    for (int i = 0; i < n; i++) {
        if (pipe(anillo[i]) == -1) {
            perror("pipe anillo");
            exit(EXIT_FAILURE);
        }
    }

    int pipe_start[2];
    if (pipe(pipe_start) == -1) {
        perror("pipe inicio");
        exit(EXIT_FAILURE);
    }

    int pipe_end[2];
    if (pipe(pipe_end) == -1) {
        perror("pipe fin");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < n; i++) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            exit(EXIT_FAILURE);
        } else if (pid == 0) {
            /* hijo */
            // cierra pipes del anillo que no usa
            for (int j = 0; j < n; j++) {
                if (j != i)
                    close(anillo[j][0]);
                if (j != (i + 1) % n)
                    close(anillo[j][1]);
            }

            // cierra extremos que no usa de pipes extra
            close(pipe_start[1]); // lee solo si es el inicial
            close(pipe_end[0]);   // escribe solo si es el ultimo

            int msg;
            if (i == inicio) {
                // inicia -> recibe del padre
                if (read(pipe_start[0], &msg, sizeof(int)) != sizeof(int)) {
                    fprintf(stderr, "Error al leer desde el padre (inicio)\n");
                    exit(EXIT_FAILURE);
                }
            } else {
                // todos los demas reciben -> (del) anterior
                if (read(anillo[i][0], &msg, sizeof(int)) != sizeof(int)) {
                    fprintf(stderr, "Error al leer de anillo (proceso %d)\n", i);
                    exit(EXIT_FAILURE);
                }
            }

            msg++;
            printf("Hijo %d recibió y aumentó el valor a: %d\n", i, msg);
            fflush(stdout);

            if (i == (inicio - 1 + n) % n) {
                // ultimo antes de 'reiniciar'
                if (write(pipe_end[1], &msg, sizeof(int)) != sizeof(int)) {
                    fprintf(stderr, "Error al escribir al padre (fin)\n");
                    exit(EXIT_FAILURE);
                }
            } else {
                if (write(anillo[(i + 1) % n][1], &msg, sizeof(int)) != sizeof(int)) {
                    fprintf(stderr, "Error al escribir al siguiente (proceso %d)\n", i);
                    exit(EXIT_FAILURE);
                }
            }

            // cierro los pipes usados
            close(anillo[i][0]);
            close(anillo[(i + 1) % n][1]);
            close(pipe_start[0]);
            close(pipe_end[1]);

            exit(EXIT_SUCCESS);
        }
    }

    /* padre */
    // cierra extremos que no usa
    for (int i = 0; i < n; i++) {
        close(anillo[i][0]);
        close(anillo[i][1]);
    }

    close(pipe_start[0]);
    close(pipe_end[1]);

    // manda valor inicial
    if (write(pipe_start[1], &valor, sizeof(int)) != sizeof(int)) {
        fprintf(stderr, "Error al enviar valor inicial\n");
        exit(EXIT_FAILURE);
    }
    close(pipe_start[1]);

    // recibe resultado final
    if (read(pipe_end[0], &valor, sizeof(int)) != sizeof(int)) {
        fprintf(stderr, "Error al recibir valor final\n");
        exit(EXIT_FAILURE);
    }
    close(pipe_end[0]);

    printf("Valor final recibido por el padre: %d\n", valor);

    // espera  a que terminen todos los hijos
    for (int i = 0; i < n; i++) {
        wait(NULL);
    }

    printf("Todos los procesos han terminado. :) \n");
    return 0;
}