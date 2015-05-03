#include "mem/cache/tags/wplru.hh"
#include "base/intmath.hh"
#include "debug/CacheRepl.hh"
#include "mem/cache/tags/cacheset.hh"
#include "mem/cache/tags/lru.hh"
#include "mem/cache/base.hh"
#include "sim/core.hh"
#include "mem/cache/blk.hh"
#include <typeinfo>

WPLRU::WPLRU( unsigned _numSets,
        unsigned _blkSize,
        unsigned _assoc,
        unsigned _hit_latency,
        unsigned _num_tcs )
    : LRU(_numSets, _blkSize, _assoc, _hit_latency ),
      num_tcs( _num_tcs )
{
    lru_tags = (LRU**) malloc(sizeof(LRU) * num_tcs);
    for(int i=0; i<_num_tcs; i++){
        lru_tags[i] = new LRU( numSets, blkSize,
                assoc_of_tc(i), _hit_latency );
    }
}
        
CacheSet WPLRU::get_set( int setnum, uint64_t tcid, Addr addr ){
    return lru_tags[tcid]->get_set(setnum, tcid, addr);
}

int
WPLRU::assoc_of_tc( int tcid ){
    int a = assoc / num_tcs;
    if(tcid < (assoc%num_tcs)) a++;
    return a;
}
