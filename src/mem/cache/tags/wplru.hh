#include "mem/cache/tags/lru.hh"
#include <sstream>
class CacheSet;

extern bool has_reset;
class WPLRU : public LRU{
    private:
    LRU** lru_tags;
    unsigned num_tcs;
    int assoc_of_tc( int tcid );

    public:
    WPLRU( unsigned _numSets, unsigned _blkSize, unsigned _assoc,
            unsigned _hit_latency, unsigned num_tcs );
    

    virtual void  invalidateBlk(BlkType *blk, uint64_t tcid){
        if(has_reset){
            lru_tags[tcid]->invalidateBlk(blk, tcid);
        } else {
            LRU::invalidateBlk(blk, tcid);
        }    
    }
    virtual BlkType* accessBlock(Addr addr, int &lat, int context_src,
            uint64_t tcid){
        if(has_reset){
            return lru_tags[tcid]->accessBlock(addr, lat, context_src, tcid);
        } else {
            return LRU::accessBlock(addr, lat, context_src, tcid);
        }
    }
    virtual BlkType* findBlock(Addr addr, uint64_t tcid){
        if(has_reset){
            return lru_tags[tcid]->findBlock(addr, tcid);
        } else {
            return LRU::findBlock(addr, tcid);
        } 
    }
    virtual BlkType* findVictim(Addr addr, PacketList &writebacks,
            uint64_t tcid){
        if(has_reset){
            return lru_tags[tcid]->findVictim(addr, writebacks, tcid);
        } else {
            return LRU::findVictim(addr, writebacks, tcid);
        }
    }
    virtual void insertBlock(Addr addr, BlkType *blk, int context_src,
             uint64_t tcid){
        if(has_reset){
            lru_tags[tcid]->insertBlock(addr, blk, context_src, tcid);
        } else {
            LRU::insertBlock(addr, blk, context_src, tcid);
        }
    }
    
    virtual CacheSet get_set( int setnum, uint64_t tcid, Addr addr );
    virtual void flush( uint64_t tcid){
        if(has_reset){
            lru_tags[tcid]->flush(tcid);
        } else {
            LRU::flush(tcid);
        }
    }
    virtual void clearLocks(uint64_t tcid){
        if(has_reset){
            lru_tags[tcid]->clearLocks(tcid);
        } else {
            LRU::clearLocks(tcid);
        }
    }
    
    virtual void cleanupRefs(){
        LRU::cleanupRefs();
        for(int i=0; i<num_tcs; i++){
            lru_tags[i]->cleanupRefs();
            totalRefs += lru_tags[i]->totalRefs.value();
            sampledRefs += lru_tags[i]->sampledRefs.value();
        }
    }
    
    virtual void regStats(const std::string &name){
        LRU::regStats(name);
        for(int i=0; i<num_tcs; i++){
            std::stringstream ss;
            ss << name << "_partition_" << i;
            lru_tags[i]->regStats(ss.str().c_str());
        }
    }
    
    void setCache(BaseCache *cache){
        LRU::setCache(cache);
        for(int i=0; i<num_tcs; i++){
            lru_tags[i]->setCache(cache);
        }
    }

    protected:
};
