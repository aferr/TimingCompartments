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
        unsigned _num_tcs,
        bool _assoc_fair )
    : LRU(_numSets, _blkSize, _assoc, _hit_latency ),
      assoc_fair( _assoc_fair),
      num_tcs( _num_tcs )
{
    // init_sets();
}

CacheSet
WPLRU::get_set( int setnum, uint64_t tid, Addr addr ){
   CacheSet s = sets_w[tid][setnum];
#ifdef DEBUG_TP
    if( s.hasBlk(interesting) ){
        printf( "get_set on interesting @ %lu", curTick() );
        s.print();
    }
#endif
    return s;
}

int WPLRU::assoc_of_tc( int tcid ){
    if(assoc_fair){
        int a = assoc / num_tcs;
        if(tcid < (assoc%num_tcs)) a++;
        return a;
    } else {
        switch(tcid){
            case 0:  return cache->params->ways0;
            case 1:  return cache->params->ways1;
            case 2:  return cache->params->ways2;
            case 3:  return cache->params->ways3;
            case 4:  return cache->params->ways4;
            case 5:  return cache->params->ways5;
            case 6:  return cache->params->ways6;
            case 7:  return cache->params->ways7;
            default: return cache->params->ways0;
        }
    }
}

int
WPLRU::blks_in_tc( int tcid ){
  return numSets * assoc_of_tc( tcid );
}

void
WPLRU::print(){
    Cache<LRU> *_cache = dynamic_cast<Cache<LRU>*>(cache);
    ccprintf(std::cout, "%i sets %i assoc [%s]\n", numSets, assoc,
            _cache->params->debug_name.c_str());
    for(int i=0; i<num_tcs; i++){
        ccprintf(std::cout, "tcid %i\n", i);
        for(int j=0; j<numSets; j++){
            ccprintf(std::cout, "set %i\n", j);
            sets_w[i][j].print();
        }
    }
}

void
WPLRU::init_sets(){
    fprintf(stderr, "init sets\n");
    sets_w = new CacheSet*[num_tcs];
    for( int i=0; i< num_tcs; i++ ){
      sets_w[i] = new CacheSet[numSets];
    }
    
    blks_by_tc = new BlkType**[num_tcs];
    for( int i=0; i < num_tcs; i++ ){
      blks_by_tc[i] = new BlkType*[blks_in_tc(i)];
    }

    numBlocks = numSets * assoc;
    blks = new BlkType[numBlocks];
    dataBlks = new uint8_t[numBlocks * blkSize];

    unsigned blkIndex = 0;
    for( unsigned tc=0; tc< num_tcs; tc++ ){
      unsigned tcIndex = 0;
        for( unsigned i = 0; i< numSets; i++ ){
            int tc_assoc = assoc_of_tc(tc);
            sets_w[tc][i].assoc = tc_assoc;
            sets_w[tc][i].blks  = new BlkType*[tc_assoc];
            for( unsigned j = 0; j<tc_assoc; j++ ){
                BlkType *blk = &blks[blkIndex];
                blk->data = &dataBlks[blkSize*blkIndex];
                ++blkIndex;

                blk->status = 0;
                blk->tag = j;
                blk->whenReady = 0;
                blk->isTouched = false;
                blk->size = blkSize;
                blk->set = i;
                sets_w[tc][i].blks[j] = blk;
                blks_by_tc[tc][tcIndex++] = blk;
            }
        }
    }
}

void
WPLRU::flush( uint64_t tcid = 0 ){
    Cache<LRU> *_cache = dynamic_cast<Cache<LRU>*>(cache);
    for( int i=0; i < blks_in_tc(tcid); i++ ){
        BlkType* b = blks_by_tc[tcid][i];
        if( b->isDirty() && b->isValid() ){
          PacketPtr wb_pkt = _cache->writebackBlk(b, tcid);
          FlushCoord::fc()->writebacks(_cache->params->hierarchy_level)->
              push_back(wb_pkt->getAddr());
          _cache->allocateWriteBuffer(wb_pkt, curTick(), true);
        }
        invalidateBlk( b, tcid );
    }
}

