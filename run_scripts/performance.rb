#------------------------------------------------------------------------------
# Performance Evaluation
#------------------------------------------------------------------------------
require_relative 'runscripts'
include RunScripts

module RunScripts

    def baseline
      iterate_mp(
        scheme: "none",
        skip3: false,
        num_wl: 8,
      )
    end
    
    def ncore_ntc
      puts $secure_opts
      iterate_mp $secure_opts.merge(
        num_wl: 8,
        skip3: false
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

      # 3 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 3,
        skip2: true,
        skip3: false,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 1,
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
      #Blocking Writeback
      bw = $secure_opts.merge(
        wbtag: "bw",
        do_flush: true,
        reserve_flush: false
      )

      #Reserved Bandwidth Writeback
      rbw = bw.merge(
          wbtag: "rbw",
          reserve_flush: true
      )

      #Insecure Writeback
      iw25, iw05, iw75 = [0.25,0.5,0.75].map do |r|
        {
          wbtag: "iw#{r.to_s.sub(/\./,'')}",
          do_insecure_flush: true,
          flushRatio: r
        }
      end

      [iw25, iw05, iw75].product([10,50,100]).each do |o,period|
        iterate_mp o.merge(
            nametag: "flush#{period}ms_#{o[:wbtag]}",
            context_sw_freq: period * 10**10
        )
      end

    end 

##############################################################################
# Coordination
##############################################################################

    $opt_l2_miss = {
      nametag: "l2miss_opt",
      l2l3req_tl: 4,
      l2l3req_offset: 2,
      l2l3resp_tl: 11,
      l2l3resp_offset: 18, 
      l3memreq_tl: 66,
      l3memreq_offset: 6,
      l3memresp_tl: 66,
      l3memresp_offset: 39,
      mem_tl: 66,
      mem_offset: 7
    }

    $bad_l2_miss = $opt_l2_miss.merge(
      nametag: "l2miss_max",
      :l2l3req_offset=>5,
      :l2l3resp_offset=>16,
      :l3memreq_offset=>121,
      :l3memresp_offset=>93,
      :mem_offset=>121
    )

    $opt_l3_hit = {
      nametag: "l3hit_opt",
      l2l3req_tl: 9,
      l2l3resp_tl: 9,
      l2l3req_offset: 0,
      l2l3resp_offset: 10
    }

    $bad_l3_hit = {
      nametag: "l3hit_max",
      l2l3req_tl: 9,
      l2l3resp_tl: 9,
      l2l3req_offset: 0,
      l2l3resp_offset: 9
    }

    $l3_miss_opt= {
      nametag: "l3miss_opt",
      l2l3req_tl:    66,
      l2l3req_offset:      0,
      l2l3resp_tl:   66,
      l2l3resp_offset:    65,
      l3memreq_tl:   66,
      l3memreq_offset:    10,
      l3memresp_tl:  66,
      l3memresp_offset:   47,
      mem_tl:        66,
      mem_offset:         11,
    }
    
    $bad_l3_miss = $l3_miss_opt.merge(
      nametag: "l3miss_max",
      :l2l3req_offset=>3,
      :l2l3resp_offset=>11,
      :l3memreq_offset=>97,
      :l3memresp_offset=>74,
      :mem_offset=>97
    )

    def parameter_tests
      o = $secure_opts.merge(
          num_wl: 2
      )

      # Optimized L2 Miss Path
      iterate_mp o.merge $opt_l2_miss

      # Worst L2 Miss Path
      iterate_mp o.merge $bad_l2_miss

      # Optimized L3 Hit Path
      iterate_mp qsub_scaling o.merge $opt_l3_hit

      # Worst L3 Miss Path
      iterate_mp qsub_scaling o.merge $bad_l3_hit
    end

end
