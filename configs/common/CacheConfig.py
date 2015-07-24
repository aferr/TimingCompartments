# Copyright (c) 2010 Advanced Micro Devices, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer;
# redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution;
# neither the name of the copyright holders nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Authors: Lisa Hsu

# Configure the M5 cache hierarchy config in one place
#

import m5
from m5.objects import *
from Caches import *
from O3_ARM_v7a import *

class L3Config(object):
    def __init__( self, options, system ):
        self.options = options
        self.system = system
        self.latencies = {
            '9MB' : '10ns',
            '6MB' : '9.25ns',
            '4MB' : '8.48ns',
            '3MB' : '7.5',
            '2MB' : '6.5ns',
            '1MB' : '5ns'
        }
        self.assocs = {
            '9MB' : 36,
            '6MB' : 24,
            '4MB' : 16,
            '3MB' : 12,
            '2MB' : 16,
            '1MB' : 16
        }

    def connect_l2( self ): return

class L3Shared( L3Config ):
    def __init__( self, options, system ):
        super( L3Shared, self ).__init__( options, system )
        L2maxWritebacks = 4096
        system.l3 = L3Cache(size = options.l3_size, 
                            latency = self.latencies[options.l3_size],
                            assoc = self.assocs[options.l3_size],
                            block_size=options.cacheline_size,
                            use_set_part = options.use_set_part,
                            num_tcs = options.numpids,
                            use_way_part = options.use_way_part,
                            split_mshrq = options.split_mshr,
                            split_rport = options.split_rport,
                            save_trace = options.do_cache_trace,
                            cw_first = not (options.nocwf),
                            do_flush = options.do_flush,
                            hierarchy_level = 3,
                            debug_name = "l3",
                            flushRatio = options.flushRatio,
                            context_sw_freq = options.context_sw_freq,
                            l3_trace_file = options.l3tracefile)

        system.tol3bus = ( 
                RR_NoncoherentBus(num_pids = options.numpids,
                            save_trace = options.do_bus_trace,
                            bus_trace_file = options.l2l3bustracefile,
                            req_tl = options.l2l3req_tl,
                            req_offset = options.l2l3req_offset,
                            resp_tl = options.l2l3resp_tl,
                            resp_offset = options.l2l3resp_offset,
                            reserve_flush = options.reserve_flush,
                            maxWritebacks = L2maxWritebacks) if options.rr_l2l3
                else NoncoherentBus()
                )
        # system.tol3bus = NoncoherentBus()
        system.l3.cpu_side = system.tol3bus.master
        system.l3.mem_side = system.membus.slave

    def connect_l2( self ):
        for i in xrange( self.options.num_cpus ):
            self.system.l2[i].mem_side = self.system.tol3bus.slave



class L3Private( L3Config ):
    def __init__( self, options, system ):
        super( L3Private , self ).__init__( options, system )
        system.l3 = [
                L3Cache(
                    size = options.l3_size,
                    latency = self.latencies[options.l3_size],
                    assoc = self.assocs[options.l3_size],
                    block_size=options.cacheline_size,
                    use_set_part = options.use_set_part,
                    num_tcs = options.numpids,
                    use_way_part = False ,
                    split_mshrq = False,
                    split_rport = False,
                    save_trace = options.do_cache_trace,
                    cw_first = not (options.nocwf),
                    do_flush = options.do_flush,
                    hierarchy_level = 3,
                    debug_name = ("l3[%i]" % i),
                    flushRatio = options.flushRatio,
                    context_sw_freq = options.context_sw_freq,
                    l3_trace_file = options.l3tracefile
                )
                for i in xrange( options.num_cpus )
            ]

        system.tol3bus = [NoncoherentBus() for i in xrange( options.num_cpus ) ]

        for i in xrange( options.num_cpus ):
            system.l3[i].cpu_side = system.tol3bus[i].master
            system.l3[i].mem_side = system.membus.slave

    def connect_l2( self ):
        for i in xrange( self.options.num_cpus ):
            self.system.l2[i].mem_side = self.system.tol3bus[i].slave


#------------------------------------------------------------------------------
# L1
#------------------------------------------------------------------------------
# Add private L1 i/d caches to each cpu
def config_l1( options, system ):
    for i in xrange(options.num_cpus):
        if options.caches:
            icache = L1Cache(size = options.l1i_size,
                             assoc = options.l1i_assoc,
                             do_flush = options.do_flush,
                             debug_name = "l1i[%i]" % i,
                             hierarchy_level = 0,
                             flushRatio = options.flushRatio,
                             context_sw_freq = options.context_sw_freq,
                             block_size=options.cacheline_size)
            dcache = L1Cache(size = options.l1d_size,
                             assoc = options.l1d_assoc,
                             do_flush = options.do_flush,
                             debug_name = "l1d[%i]" % i,
                             hierarchy_level = 1,
                             flushRatio = options.flushRatio,
                             context_sw_freq = options.context_sw_freq,
                             block_size=options.cacheline_size)

            if buildEnv['TARGET_ISA'] == 'x86':
                system.cpu[i].addPrivateSplitL1Caches(icache, dcache,
                                                      PageTableWalkerCache(),
                                                      PageTableWalkerCache())
            else:
                system.cpu[i].addPrivateSplitL1Caches(icache, dcache)
        system.cpu[i].createInterruptController()


#------------------------------------------------------------------------------
# L2
#------------------------------------------------------------------------------
def config_l2( options, system ):
    system.l2 = [ 
            L2Cache( 
                size = options.l2_size,
                assoc = options.l2_assoc,
                save_trace = options.do_cache_trace,
                l3_trace_file = options.l2tracefile,
                block_size=options.cacheline_size,
                do_flush = options.do_flush,
                hierarchy_level = 2,
                debug_name = "l2[%i]" % i,
                flushRatio = options.flushRatio,
                context_sw_freq = options.context_sw_freq,
            ) 
            for i in xrange( options.num_cpus )
        ]
    system.tol2bus = [NoncoherentBus() for i in xrange( options.num_cpus )]

# Connect private L2 caches to the cached ports of each cpu (usually l1)
# through system.tol2bus
def connect_l2( options, system ):
    for i in xrange(options.num_cpus):
        if options.l2cache:
            system.cpu[i].connectAllPorts(system.tol2bus[i])
            system.l2[i].cpu_side = system.tol2bus[i].master
            if not options.l3cache:
                system.l2[i].mem_side = system.membus.slave
        else:
            system.cpu[i].connectAllPorts(system.membus)


def config_cache(options, system):

    #-------------------------------------------------------------------------
    # L3
    #-------------------------------------------------------------------------
    if options.l3cache:
        if options.l3config == "shared":
            l3config = L3Shared( options, system )
        else:
            l3config = L3Private( options, system )

    #-------------------------------------------------------------------------
    # L1
    #-------------------------------------------------------------------------
    
    config_l1( options, system )

    #-------------------------------------------------------------------------
    # L2
    #-------------------------------------------------------------------------
    config_l2( options, system )
    connect_l2( options, system )

    if options.l3cache:
        l3config.connect_l2()

    return system
