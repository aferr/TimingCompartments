#------------------------------------------------------------------------------
# Performance Evaluation
#------------------------------------------------------------------------------
require_relative 'runscripts'
include RunScripts

module RunScripts

    def baseline
      iterate_mp(
        scheme: "none",
        num_wl: 8,
      )
    end
    
    def ncore_ntc
      puts $secure_opts
      iterate_mp $secure_opts.merge(
        num_wl: 8,
      )
    end

    def breakdown

      o = {
        schemes: %w[none],
        scheme: "none",
        addrpar: true,
        num_wl: 2,
      }

      iterate_mp o.merge(
        nametag: "only_rrbus",
        rr_nc: true,
        split_rport: true,
      )

      # parallel_local o.merge(
      iterate_mp o.merge(
        nametag: "only_waypart",
        waypart: true,
      )

      iterate_mp o.merge(
        nametag: "only_mc",
        schemes: %w[tp],
        scheme: "tp"
      )

    end

    def ncore_2tc
      o = $secure_opts.merge(
        nametag: "2tc"
      )

      # 4 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 4,
        skip2: true,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 1,
        p3threadID: 1
      )

      # 6 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 6,
        skip2: true,
        skip4: true,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 0,
        p3threadID: 1,
        p4threadID: 1,
        p5threadID: 1
      )

      # 8 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 8,
        skip2: true,
        skip4: true,
        skip6: true,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 0,
        p3threadID: 0,
        p4threadID: 1,
        p5threadID: 1,
        p6threadID: 1,
        p7threadID: 1
      )

    end

    def flush_overhead
      [$secure_opts].each do |opt|
        o = opt.merge(
          do_flush: true,
        )
        #10 ms
        iterate_mp o.merge(nametag: "flush1ms", context_sw_freq: 10**7)
        #50 ms
        iterate_mp o.merge(nametag: "flush10ms", context_sw_freq: 5*10**7)
        #100 ms
        iterate_mp o.merge(nametag: "flush100ms", context_sw_freq: 10**8)
      end
    end 

##############################################################################
# Coordination
##############################################################################

    $opt_l2_miss = {
      l2l3req_tl: 4,
      l2l3req_o: 2,
      l2l3resp_tl: 11,
      l2l3resp_o: 18, 
      l3memreq_tl: 66,
      l3memreq_o: 6,
      l3memresp_tl: 66,
      l3memresp_o: 39,
      mem_tl: 66,
      mem_o: 7
    }

    $bad_l2_miss = $opt_l2_miss.merge(
      l2l3req_o: 114,
      l2l3resp_o: 53,
      l3memreq_o: 57,
      l3memresp_o: 29,
      mem_o: 54
    )

    $opt_l3_hit = {
      l2l3req_tl: 9,
      l2l3resp_tl: 9,
      l2l3req_o: 0,
      l2l3resp_o: 10
    }

    $bad_l3_hit = {
      l2l3req_tl: 9,
      l2l3resp_tl: 9,
      l2l3req_o: 0,
      l2l3resp_o: 9
    }

    def parameter_tests
      o = $secure_opts.merge(
        skip3: true,
        skip4: true
      )

      # Optimized L2 Miss Path
      qsub_scaling o.merge $opt_l2_miss

      # Worst L2 Miss Path
      qsub_scaling o.merge $bad_l2_miss

      # Optimized L3 Hit Path
      qsub_scaling o.merge $opt_l3_hit

      # Worst L3 Miss Path
      qsub_scaling o.merge $bad_l3_hit
    end

end
