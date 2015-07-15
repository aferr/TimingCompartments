#include "stdio.h"
#include "mem/packet.hh"
#include <iostream>
#include <list>
#include "base/cprintf.hh"

class BaseCache;

class FlushCoord {
    public:
    BaseCache *l1i;
    BaseCache *l1d;
    BaseCache *l2;
    BaseCache *l3;
    std::list<Addr> *l1i_writebacks;
    std::list<Addr> *l1d_writebacks;
    std::list<Addr> *l2_writebacks;
    std::list<Addr> *l3_writebacks;

    bool l2_flushed;
    bool l3_flushed;
    
    std::list<Addr>* writebacks(int level);

    void flush_call(BaseCache* c);
    void finish_writeback(Addr addr, int level);
    void check_writebacks();
    bool flush_blocked();

    void print_writebacks();

    private:
    FlushCoord();
    FlushCoord(FlushCoord const&){}
    FlushCoord& operator=(FlushCoord const&){return *this;}
    static FlushCoord *instance;
    
    public: 
    static FlushCoord* fc();
};

// Blocking writeback flush procedure:

// Common flush procedure:
// 1: generate writeback requests from the modified blocks
// 2: push a list of generated writebacks to the global flush procedure state
// 2: make a number of bus requests equal to the number of modified blocks
// 3: invalidate all cache blocks
// 4: when each writeback completes, remove it from the list. If the list is 
// empty, the writebacks are done for this level and the next one can be done

// Periodically call flush() for L1i/d
// L1 i/d flush:
// 1: block the l1i/d caches
// 2: perform common flush procedure
// 3: When l1i and l1d flushes are both done, call l2 flush

// L2 flush:
// 1: perform common flush procedure
// 2: call l3 flush

// L3 flush:
// 1: perform common flush procedure only for the partition of interest
// 2: tell the L1i/d caches to clear the block
