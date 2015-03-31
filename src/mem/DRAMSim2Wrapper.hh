/*
 * Copyright (c) 2012 ARM Limited
 * All rights reserved
 *
 * The license below extends only to copyright in the software and shall
 * not be construed as granting a license to any other intellectual
 * property including but not limited to intellectual property relating
 * to a hardware implementation of the functionality of the software
 * licensed hereunder.  You may use the software subject to the license
 * terms below provided that you ensure that this notice is replicated
 * unmodified and in its entirety in all distributions of the software,
 * modified or unmodified, in source code or in binary form.
 *
 * Copyright (c) 2001-2005 The Regents of The University of Michigan
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Ron Dreslinski
 *          Andreas Hansson
 */

/**
 * @file
 * DRAMSim2Wrapper declaration
 */

#ifndef __DRAMSIM2WRAPPER_HH__
#define __DRAMSIM2WRAPPER_HH__

#include "mem/abstract_mem.hh"
#include "mem/tport.hh"
#include "mem/trace_printer.hh"
#include "params/DRAMSim2Wrapper.hh"

#include "MultiChannelMemorySystem.h"

/**
 * The simple memory is a basic single-ported memory controller with
 * an infinite throughput and a fixed latency, potentially with a
 * variance added to it. It uses a SimpleTimingPort to implement the
 * timing accesses.
 */

extern DRAMSim::MultiChannelMemorySystem *dramsim2;
class DRAMSim2Wrapper : public AbstractMemory
{

  public:

    void updateDRAMSim2(){
            while ( (double)dramsim2->currentClockCycle
                    <= (double)(curTick()) / 1000.0 / tCK) {
                dramsim2->update();
            }
    }

    class MemoryPort : public SimpleTimingPort
    {

      public:
        SlavePacketQueue** respQueues;

        DRAMSim2Wrapper* memory;
        MemoryPort(const std::string& _name, DRAMSim2Wrapper* _memory, int numPids);
        void removePendingDelete()
        {
            for (int x = 0; x < pendingDelete.size(); x++)
                delete pendingDelete[x];
            pendingDelete.clear();
        }
        void addPendingDelete(PacketPtr pkt)
        {
            pendingDelete.push_back(pkt);
        }

        virtual void schedTimingResp(PacketPtr pkt, Tick when, int threadID)
        {
            QueuedSlavePort::schedTimingResp( pkt, when, threadID );
        }

        virtual void schedTimingResp(PacketPtr pkt, Tick when ){
            QueuedSlavePort::schedTimingResp( pkt, when );
        }
        virtual void recvRetry() { QueuedSlavePort::recvRetry(); }

      protected:

        virtual Tick recvAtomic(PacketPtr pkt);

        virtual void recvFunctional(PacketPtr pkt);

        virtual bool recvTimingReq(PacketPtr pkt);

        virtual AddrRangeList getAddrRanges() const;

    };

    class SplitMemoryPort : public MemoryPort
    {
        public:
        SplitMemoryPort( const std::string& _name, DRAMSim2Wrapper* _memory,
                int numPids )
            : MemoryPort( _name, _memory, numPids )
        {}

        virtual void schedTimingResp(PacketPtr pkt, Tick when, int threadID)
        { 
            memory->tracePrinter->addTrace( pkt, "split schedSendTiming" );
            this->respQueues[threadID]->schedSendTiming(pkt, when);
        }

        virtual void recvRetry( int threadID ){
            respQueues[threadID]->retry();
        }

    };

    int numPids;
	MemoryPort* port;

    Tick lat;
    Tick lat_var;


  public:
    TracePrinter * tracePrinter;

    typedef DRAMSim2WrapperParams Params;
    DRAMSim2Wrapper(const Params *p);
    virtual ~DRAMSim2Wrapper() { }

    unsigned int drain(Event* de);

    virtual SlavePort& getSlavePort(const std::string& if_name, int idx = -1);
    virtual void init();

    const Params *
    params() const
    {
        return dynamic_cast<const Params *>(_params);
    }

  protected:

    Tick doAtomicAccess(PacketPtr pkt);
    void doFunctionalAccess(PacketPtr pkt);
    virtual Tick calculateLatency(PacketPtr pkt);

};

#endif //__DRAMSIM2WRAPPER_HH__
