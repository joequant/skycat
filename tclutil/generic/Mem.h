// -*-c++-*-
#ifndef _Mem_h_
#define _Mem_h_
/*
 * E.S.O. - VLT project / ESO Archive
 *
 * "@(#) $Id: Mem.h,v 1.1.1.1 2009/03/31 14:11:52 cguirao Exp $" 
 *
 * Mem.h - declarations for class Mem, a class for managing memory areas,
 *         which may or may not be shared memory.
 *
 * who             when       what
 * --------------  --------   ----------------------------------------
 * Allan Brighton  07 Mar 96  Created
 *                 03 Dec 96  added filename() method to return mmap filename
 *                            or NULL if mmap is not being used.
 * D.Hopkinson      21/01/97  Added constructor to use when
 *                            multi-buffering  shared memory.
 * Peter W. Draper  23/01/00  Added constructor and methods for
 *                            accepting a piece of malloc'd memory.
 *                  03/09/04  Added addr parameter to Mem and Mem_Rep
 *                            constructors. Starlink fortran 64 bit
 *                            interoperability requires that addresses may be
 *                            changed.
 *                  04/04/06  Added "refcnt" member so that owner can control
 *                            when to release memory.
 *                  05/12/07  Change length function to return off_t instead
 *                            of int.
 */

#include <cstdio>
#include <sys/types.h>
class Mem_Map;

// internal struct used for reference counting
struct MemRep {
    size_t size;		// size in bytes
    int owner;			// true if we should delete the shm when no longer needed
    int refcnt;			// count of the number of reference to this memory area
    void* ptr;			// pointer to memory area
    int newmem;                 // memory allocated using "new"
    int shmId;			// shared memory id, or 0 if not shared
    int shmNum;                 // shm buffer number, if multi-buffering
    int semId;                  // Semaphore ID for locking shm
    int options;		// mmap options for read/write access
    int status;			// status after constructor
    int verbose;		// if true, print diagnostic messages
    Mem_Map *m_map;             // Used when mapping a file
    char* linkName;		// If a file name specified for mmap was a link, it is
				// replaced with the real name and the name of the link
				// is recorded here.

    // default constructor: empty memory
    MemRep();

    // attach to sysV shared memory
    MemRep(size_t size, int owner, int shmId, int verbose);

    // create memory (sysV shared, if useShm is 1) with given size
    MemRep(size_t size, int useShm, int verbose);

    // mmap the given file, create/extend if nbytes > 0
    MemRep(const char *filename, int flags, int prot, int share,
           size_t nbytes, int owner, int verbose, void *addr = NULL);

    // accept pointer to malloc'd memory.
    MemRep(void *inptr, size_t size, int owner);

    // destructor
    ~MemRep();

    // return name of mmap file or NULL if mmap not being used
    const char* filename(int flag = 0) const;

    // temporarily unmap the shared memory
    void unmap();

    // remap the shared memory after a call to unmap(), optionally specifying
    // new mapping options and a new file size.
    int remap(int options = 0, size_t newsize = 0);

};


/*
 * This class uses reference counting to help manage memory areas.  The
 * class keeps track of who owns the (shared) memory, who is responsible
 * for deleting it when no longer needed and how many references there
 * are to the memory area. When there are no more references, we
 * can safely detach a shared memory area and if we are the "owner",
 * delete it.
 */
class Mem {
private:
    MemRep* rep_;		// internal representation, reference counting
    long offset_;		// optional offset in memory area
    long length_;		// optional different length of memory area used

public:
    // default constructor
    Mem() : rep_(new MemRep), offset_(0), length_(0) { 
    }

    // constructor: attach (if needed) to existing shared memory area
    Mem(size_t size, int shmId, int owner, int verbose);

    // constructor: create new memory area, shared if useShm is true
    Mem(size_t size, int useShm, int verbose = 0) 
	: rep_(new MemRep(size, useShm, verbose)), offset_(0), length_(0) {
    }

    // mmap options
    enum MemFileOptions {
	FILE_DEFAULTS = 0,   // File RDONLY, MAP_SHARED
	FILE_RDWR = 1,       // Make mapped file writable
	FILE_PRIVATE = 2,    // Make written segments private
	FILE_FIXED = 4       // Fixed address, not in use
    };

    // Constructor uses mmap to map a file
    Mem(const char *filename, int verbose = 0);

    // Constructor uses mmap to map a file and adds file options
    // PWD: Use the addr argument if you need to suggest an address to map
    // the file. Starlink Fortran interoperability sometimes needs this.
    Mem(const char *filename, int options, int verbose, void *addr = NULL);

    // Constructor: creates a file of the given size and uses mmap
    // to map the file read/write.
    Mem(size_t size, const char *filename, int owner, int verbose = 0 );

    // Constructor to use when multi-buffering shared memory.
    Mem(size_t size, int shmId, int owner, int verbose, int shmNum, int semId);

    // Accept pointer to malloc'd memory
    Mem(void *ptr, size_t size, int owner);

    // copy constructor, just copy ptr and increment ref count
    Mem(const Mem& m)
	: rep_(m.rep_), offset_(m.offset_), length_(m.length_) {
	    rep_->refcnt++;
    }

    // destructor, detach and/or delete memory if needed
    ~Mem();

    // assignment
    Mem& operator=(const Mem&);

    int operator==(const Mem& m) const {
	return m.rep_ == rep_ && m.offset_ == offset_ && m.length_ == length_;
    }
    int operator!=(const Mem& m) const {
	return m.rep_ != rep_ || m.offset_ != offset_ || m.length_ != length_;
    }

    //  reference counts of memory
    int refcnt();

    // return true if the memory is shared
    int shared() const {return shmId() >= 0;}

    // force the memory to be shared (1) or not shared (0)
    int shared(int share);

    // temporarily unmap the shared memory
    void unmap() {rep_->unmap();}

    // remap the shared memory after a call to unmap(), optionally specifying
    // new mapping options and a new file size
    int remap(int options = 0, size_t newsize = 0) {
	return rep_->remap(options, newsize);
    }

    // remove all "owned" shared memory areas (should be called before exit)
    static void cleanup();

    // return the working length of the memory
    off_t length() const {return off_t(length_ ? length_ : (rep_->size - offset_));}

    // set optional length
    void length(long newLength) {length_ = newLength;}

    // member access
    size_t size() const {return rep_->size;}
    void* ptr() const {return rep_->ptr ? ((void *)((char *)rep_->ptr + offset_)) : NULL;}
    int shmId() const {return rep_->shmId;}
    int shmNum() const {return rep_->shmNum;}
    int semId() const {return rep_->semId;}
    int options() const {return rep_->options;}
    int status() const {return rep_->status;}
    int verbose() const {return rep_->verbose;}
    Mem_Map* m_map() const {return rep_->m_map;}

    // return a pointer to the internal representation
    // (This should only be used, if needed, in special cases)
    const MemRep* rep() const {return rep_;}

    // set/get the owner flag: if non-zero, memory will be deleted when there
    // are no more references
    void owner(int b) {rep_->owner = b;}
    int owner() {return rep_->owner;}

    // return name of mmap file or NULL if mmap not being used
    const char* filename(int flag = 0) const {return rep_->filename(flag);}

    // set/get offset
    void offset(long newOffset) {offset_ = newOffset;}
    long offset() const {return offset_;}

  };

/* cleanup shared mem and exit: for use as a signal handler */
void Mem_cleanup(int);


#endif /* _Mem_h_ */
