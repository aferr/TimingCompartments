#include "mem/cache/tags/lru.hh"

class WPLRU : public LRU{
    private:
    CacheSet **sets_w;

    public:
    WPLRU( unsigned _numSets, unsigned _blkSize, unsigned _assoc,
            unsigned _hit_latency, unsigned num_tcs );

    // Cache<WPLRU> *cache;
    // virtual void setCache(Cache<WPLRU> *_cache){ cache = _cache; }
    virtual void flush( uint64_t tcid );

    protected:
    BlkType ***blks_by_tc;
    unsigned num_tcs;
    virtual void init_sets();
    virtual CacheSet get_set( int setnum, uint64_t tid, Addr addr );
    // virtual void cleanupRefs();

    int blks_in_tc( int tcid );
    virtual int assoc_of_tc( int tcid );
};
