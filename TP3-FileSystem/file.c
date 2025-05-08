#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "file.h"
#include "inode.h"
#include "diskimg.h"
#include "ino.h"

/**
 * TODO
 */
int file_getblock(struct unixfilesystem *fs, int inumber, int blockNum, void *buf) {
    struct inode in;
    if (inode_iget(fs, inumber, &in) == -1) {
        return -1;
    }

    int diskBlockNum = inode_indexlookup(fs, &in, blockNum);
    if (diskBlockNum == -1) {
        return -1;
    }

    int res = diskimg_readsector(fs->dfd, diskBlockNum, buf);
    if (res == -1) {
        return -1;
    }

    int fileSize = (in.i_size0 << 16) | in.i_size1;
    int blockStartByte = blockNum * DISKIMG_SECTOR_SIZE;

    if (blockStartByte >= fileSize) {
        return 0;
    }

    int remainingBytes = fileSize - blockStartByte;
    if (remainingBytes >= DISKIMG_SECTOR_SIZE) {
        return DISKIMG_SECTOR_SIZE;
    }

    return remainingBytes;
}

