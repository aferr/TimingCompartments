/*
 * Copyright (c) 2011-2012 ARM Limited
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
 * Copyright (c) 2006 The Regents of The University of Michigan
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
 * Authors: Ali Saidi
 *          Andreas Hansson
 *          William Wang
 */

/**
 * @file
 * Definition of a bus object.
 */

#include "base/misc.hh"
#include "base/trace.hh"
#include "base/callback.hh"
#include "debug/Bus.hh"
#include "debug/BusAddrRanges.hh"
#include "debug/NoncoherentBus.hh"
#include "mem/rr_noncoherent_bus.hh"

RR_NoncoherentBus::RR_NoncoherentBus(const RR_NoncoherentBusParams *p)
    : RRBus(p), reqLayer(*this, ".reqLayer", p->clock, p->req_tl, p->req_offset),
      respLayer(*this, ".respLayer", p->clock, p->resp_tl, p->resp_offset),
	  req_tl(p->req_tl), req_offset(p->req_offset), resp_tl(p->resp_tl), resp_offset(p->resp_offset)
{
    // create the ports based on the size of the master and slave
    // vector ports, and the presence of the default port, the ports
    // are enumerated starting from zero
    for (int i = 0; i < p->port_master_connection_count; ++i) {
        std::string portName = csprintf("%s.master[%d]", name(), i);
        MasterPort* bp = new RR_NoncoherentBusMasterPort(portName, *this, i);
        fprintf(stderr, "master: %s\n", portName.c_str());
        masterPorts.push_back(bp);
    }

    // see if we have a default slave device connected and if so add
    // our corresponding master port
    if (p->port_default_connection_count) {
        defaultPortID = masterPorts.size();
        std::string portName = name() + ".default";
        MasterPort* bp = new RR_NoncoherentBusMasterPort(portName, *this,
                                                      defaultPortID);
        masterPorts.push_back(bp);
    }

    // create the slave ports, once again starting at zero
    for (int i = 0; i < p->port_slave_connection_count; ++i) {
        std::string portName = csprintf("%s.slave[%d]", name(), i);
        SlavePort* bp = new RR_NoncoherentBusSlavePort(portName, *this, i);
        slavePorts.push_back(bp);
    }

    busTrace = new TracePrinter( p->bus_trace_file, p );

    clearPortCache();
    params = p;
}

bool
RR_NoncoherentBus::recvTimingReq(PacketPtr pkt, PortID slave_port_id)
{
    // determine the source port based on the id
    SlavePort *src_port = slavePorts[slave_port_id];

    // we should never see express snoops on a non-coherent bus
    assert(!pkt->isExpressSnoop());

    busTrace->addTrace( pkt, "recvTimingReq" );

    //if(pkt->threadID == 0 && curTick() > 2820000000) printf("receive timing request %llx from %llu @ cycle %llu\n", pkt->getAddr(), pkt->threadID, curTick());
	// test if the bus should be considered occupied for the current
    // port
    if (!reqLayer.tryTiming(src_port, pkt->threadID)) {
        DPRINTF(NoncoherentBus, "recvTimingReq: src %s %s 0x%x BUSY\n",
                src_port->name(), pkt->cmdString(), pkt->getAddr());
        return false;
    }

    DPRINTF(NoncoherentBus, "recvTimingReq: src %s %s 0x%x\n",
            src_port->name(), pkt->cmdString(), pkt->getAddr());

    // set the source port for routing of the response
    pkt->setSrc(slave_port_id);

    Tick headerFinishTime =calcPacketTiming(pkt, pkt->threadID, req_tl, req_offset);
    Tick packetFinishTime = pkt->finishTime;

    // since it is a normal request, determine the destination
    // based on the address and attempt to send the packet
    bool success = masterPorts[findPort(pkt->getAddr())]->sendTimingReq(pkt);

    if (!success)  {
        // inhibited packets should never be forced to retry
        assert(!pkt->memInhibitAsserted());

        DPRINTF(NoncoherentBus, "recvTimingReq: src %s %s 0x%x RETRY\n",
                src_port->name(), pkt->cmdString(), pkt->getAddr());

        reqLayer.failedTiming(src_port, headerFinishTime, pkt->threadID);

        return false;
    }

    reqLayer.succeededTiming(packetFinishTime, pkt->threadID);

    return true;
}

bool
RR_NoncoherentBus::recvTimingResp(PacketPtr pkt, PortID master_port_id)
{
    // determine the source port based on the id
    MasterPort *src_port = masterPorts[master_port_id];

    busTrace->addTrace( pkt, "recvTimingResp" );

    // test if the bus should be considered occupied for the current
    // port
    //if(pkt->threadID == 0 && curTick() > 2820000000) printf("receive timing response %llx from %llu @ cycle %llu\n", pkt->getAddr(), pkt->threadID, curTick());
	if (!respLayer.tryTiming(src_port, pkt->threadID)) {
        DPRINTF(NoncoherentBus, "recvTimingResp: src %s %s 0x%x BUSY\n",
                src_port->name(), pkt->cmdString(), pkt->getAddr());
        return false;
    }

    DPRINTF(NoncoherentBus, "recvTimingResp: src %s %s 0x%x\n",
            src_port->name(), pkt->cmdString(), pkt->getAddr());

    calcPacketTiming(pkt, pkt->threadID, resp_tl, resp_offset);
    Tick packetFinishTime = pkt->finishTime;

    // send the packet to the destination through one of our slave
    // ports, as determined by the destination field
    bool success M5_VAR_USED = slavePorts[pkt->getDest()]->sendTimingResp(pkt);

    // currently it is illegal to block responses... can lead to
    // deadlock
    assert(success);

    respLayer.succeededTiming(packetFinishTime, pkt->threadID);

    return true;
}

void
RR_NoncoherentBus::recvRetry()
{
    // responses never block on forwarding them, so the retry will
    // always be coming from a port to which we tried to forward a
    // request
    for (int i = 0; i < num_pids; i++)
		reqLayer.recvRetry(i);
}

Tick
RR_NoncoherentBus::recvAtomic(PacketPtr pkt, PortID slave_port_id)
{
    DPRINTF(NoncoherentBus, "recvAtomic: packet src %s addr 0x%x cmd %s\n",
            slavePorts[slave_port_id]->name(), pkt->getAddr(),
            pkt->cmdString());

    busTrace->addTrace( pkt, "recvAtomic" );

    // determine the destination port
    PortID dest_id = findPort(pkt->getAddr());

    // forward the request to the appropriate destination
    Tick response_latency = masterPorts[dest_id]->sendAtomic(pkt);

    pkt->finishTime = curTick() + response_latency;
    return response_latency;
}

void
RR_NoncoherentBus::recvFunctional(PacketPtr pkt, PortID slave_port_id)
{
    if (!pkt->isPrint()) {
        // don't do DPRINTFs on PrintReq as it clutters up the output
        DPRINTF(NoncoherentBus,
                "recvFunctional: packet src %s addr 0x%x cmd %s\n",
                slavePorts[slave_port_id]->name(), pkt->getAddr(),
                pkt->cmdString());
    }


    // determine the destination port
    PortID dest_id = findPort(pkt->getAddr());

    // forward the request to the appropriate destination
    masterPorts[dest_id]->sendFunctional(pkt);
}

unsigned int
RR_NoncoherentBus::drain(Event *de)
{
    // sum up the individual layers
    return reqLayer.drain(de) + respLayer.drain(de);
}

RR_NoncoherentBus*
RR_NoncoherentBusParams::create()
{
    return new RR_NoncoherentBus(this);
}

