#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"
#include "unixfilesystem.h"
#include "ino.h"

#define INODES_PER_SECTOR (DISKIMG_SECTOR_SIZE / sizeof(struct inode))
#define PTRS_PER_BLOCK (DISKIMG_SECTOR_SIZE / sizeof(uint16_t))

/*
 * inode_iget - Read an inode from the disk image.
 */
int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inp) {
    if (inumber < 1) {
        return -1; 
    }

    int inode_index = inumber - 1;
    int sector = INODE_START_SECTOR + inode_index / INODES_PER_SECTOR;

    char buf[DISKIMG_SECTOR_SIZE];
    int res = diskimg_readsector(fs->dfd, sector, buf);
    if (res == -1) {
        return -1; 
    }

    struct inode *inodes = (struct inode *)buf;
    *inp = inodes[inode_index % INODES_PER_SECTOR]; 
    return 0;
}

/*
 * inode_indexlookup - Look up the block number for a given block index in an inode.
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int blockNum) {
    if (blockNum < 0) {
        return -1;
    }

    if (!(inp->i_mode & ILARG)) {
        if (blockNum >= 8) {
            return -1;
        }
        return inp->i_addr[blockNum];
    }

    if (blockNum < (int)(7 * PTRS_PER_BLOCK)) {
        int indir_block = inp->i_addr[blockNum / PTRS_PER_BLOCK];
        if (indir_block == 0) {
            return -1;
        }

        uint16_t buffer[PTRS_PER_BLOCK];
        int res = diskimg_readsector(fs->dfd, indir_block, buffer);
        if (res == -1) {
            return -1;
        }

        return buffer[blockNum % PTRS_PER_BLOCK];
    }

    int double_indir_offset = blockNum - 7 * PTRS_PER_BLOCK;

    int double_indir_block = inp->i_addr[7];
    if (double_indir_block == 0) {
        return -1;
    }

    uint16_t indir_blocks[PTRS_PER_BLOCK];
    int res1 = diskimg_readsector(fs->dfd, double_indir_block, indir_blocks);
    if (res1 == -1) {
        return -1;
    }

    int outer_index = double_indir_offset / PTRS_PER_BLOCK;
    int inner_index = double_indir_offset % PTRS_PER_BLOCK;

    int inner_block = indir_blocks[outer_index];
    if (inner_block == 0) {
        return -1;
    }

    uint16_t data_blocks[PTRS_PER_BLOCK];
    int res2 = diskimg_readsector(fs->dfd, inner_block, data_blocks);
    if (res2 == -1) {
        return -1;
    }

    return data_blocks[inner_index];
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1); 
}
