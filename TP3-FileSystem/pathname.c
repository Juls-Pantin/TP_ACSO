
#include "pathname.h"
#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "unixfilesystem.h"
#include "direntv6.h"

/**
 * TODO
 */
int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    if (pathname == NULL || pathname[0] != '/') {
        return -1;
    }

    char pathCopy[1024];
    strncpy(pathCopy, pathname, sizeof(pathCopy));
    pathCopy[sizeof(pathCopy) - 1] = '\0';

    char *token = strtok(pathCopy, "/");
    int currentInumber = 1;
    while (token != NULL) {
        struct direntv6 entry;
        if (directory_findname(fs, token, currentInumber, &entry) == -1) {
            return -1; 
        }

        currentInumber = entry.d_inumber;
        token = strtok(NULL, "/");
    }

    return currentInumber;
}
