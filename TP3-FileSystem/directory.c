#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "direntv6.h"
#include "unixfilesystem.h"

/**
 * TODO
 */
int directory_findname(struct unixfilesystem *fs, const char *name,
		int dirinumber, struct direntv6 *dirEnt) {
      struct inode dir_inode;
      if (inode_iget(fs, dirinumber, &dir_inode) == -1) {
        return -1;
    }

    int blockNum = 0;
    char data[DISKIMG_SECTOR_SIZE];

    while (1) {
        int nbytes = file_getblock(fs, 1, blockNum, data);
        if (nbytes <= 0) {
            break; // no hay más bloques o error
        }

        int offset = 0;
        while (offset + sizeof(struct direntv6) <= nbytes) {
            struct direntv6 *entry = (struct direntv6 *)(data + offset);

            // Comparar nombres con strncmp (no están null-terminated)
            if (strncmp(entry->d_name, name, sizeof(entry->d_name)) == 0) {
              memcpy(dirEnt, entry, sizeof(struct direntv6));
              return 0;
            }

            offset += sizeof(struct direntv6);
        }

        blockNum++;
    }

    return -1;
}
