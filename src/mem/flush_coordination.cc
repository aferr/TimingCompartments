#ifndef __BASE_CACHE_HH__
    #include "mem/cache/base.hh"
#endif

FlushCoord* FlushCoord::instance = NULL;
FlushCoord* FlushCoord::fc(){
    if(!instance) instance = new FlushCoord();
    return instance;
}

FlushCoord::FlushCoord(){
    l1i_writebacks = new std::list<Addr>();
    l1d_writebacks = new std::list<Addr>();
    l2_writebacks  = new std::list<Addr>();
    l3_writebacks  = new std::list<Addr>();
}

std::list<Addr>* FlushCoord::writebacks(int level){
    return level == 0 ? l1i_writebacks :
        level == 1 ? l1d_writebacks :
        level == 2 ? l2_writebacks :
        level == 3 ? l3_writebacks :
        NULL;
}

void FlushCoord::finish_writeback(Addr addr, int level){
    for(int i=0; i<4; i++){
        for(std::list<Addr>::iterator it = writebacks(i)->begin();
                it != writebacks(i)->end(); ++it){
            if(addr == *it){ 
                writebacks(i)->erase(it); break;
            }
        }
    }
    check_writebacks();
}

void FlushCoord::check_writebacks(){
    if( l1i_writebacks->empty() && l1d_writebacks->empty() &&
            l2_writebacks->empty() && l3_writebacks->empty() &&
            l2_flushed && l3_flushed ){
        l1d->clearBlocked(BaseCache::Blocked_DrainingWritebacks);
        l1i->clearBlocked(BaseCache::Blocked_DrainingWritebacks);
        l1d->flush_block_time+= (curTick() - l1d->last_flush_block_start);
        l1i->flush_block_time+= (curTick() - l1i->last_flush_block_start);
        l1i->is_flush_blocked = false;
        l1d->is_flush_blocked = false;
        return;
    }

    if(!l2_flushed && l1i_writebacks->empty() && l1d_writebacks->empty()){
        l2_flushed = true;
        l2->flush(0);
        return;
    }

    if(l2_flushed && !l3_flushed && l2_writebacks->empty()){
        l3_flushed = true;
        l3->flush(0);
        return;
    }
}

// Begins a flush when called by an l1 cache.
void FlushCoord::flush_call(BaseCache* c){
    if( c == l1i || c == l1d ){
        l1i->setBlocked(BaseCache::Blocked_DrainingWritebacks);
        l1d->setBlocked(BaseCache::Blocked_DrainingWritebacks);
        l1i->is_flush_blocked = true;
        l1d->is_flush_blocked = true;
        l1i->flush_blocked_tcid = 0;
        l1d->flush_blocked_tcid = 0;
        l1i->last_flush_block_start = curTick();
        l1d->last_flush_block_start = curTick();
        l2_flushed= false;
        l3_flushed = false;
    }
}

void FlushCoord::print_writebacks(){
    ccprintf( std::cout, "l1i_writebacks:\n");
    for(std::list<Addr>::iterator it = l1i_writebacks->begin();
            it != l1i_writebacks->end(); ++it){
        ccprintf( std::cout, "%i\n", *it );
    }
    ccprintf( std::cout, "l1d_writebacks:\n");
    for(std::list<Addr>::iterator it = l1d_writebacks->begin();
            it != l1d_writebacks->end(); ++it){
        ccprintf( std::cout, "%i\n", *it );
    }
    ccprintf( std::cout, "l2_writebacks:\n");
    for(std::list<Addr>::iterator it = l2_writebacks->begin();
            it != l2_writebacks->end(); ++it){
        ccprintf( std::cout, "%i\n", *it );
    }
    ccprintf( std::cout, "l3_writebacks:\n");
    for(std::list<Addr>::iterator it = l3_writebacks->begin();
            it != l3_writebacks->end(); ++it){
        ccprintf( std::cout, "%i\n", *it );
    }
}

bool FlushCoord::flush_blocked(){
    return l1i->is_flush_blocked || l1d->is_flush_blocked;
}
