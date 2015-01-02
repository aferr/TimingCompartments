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
      :l2l3req_tl=>1,
      :l2l3req_offset=>16,
      :l2l3resp_tl=>9,
      :l2l3resp_offset=>10,
      :membusreq_tl=>26,
      :membusreq_offset=>8,
      :membusresp_tl=>9,
      :membusresp_offset=>61,
      :mem_tl=>52,
      :mem_offsetffset=>4
    }

    $opt_l2_old = {
      nametag: "l2miss_opt_old",
      :l2l3req_tl=>1,
      :l2l3req_offset=>8,
      :l2l3resp_tl=>13,
      :l2l3resp_offset=>11,
      :membusreq_tl=>60,
      :membusreq_offset=>33,
      :membusresp_tl=>14,
      :membusresp_offset=>34,
      :mem_tl=>70,
      :mem_offset=>79
    }

    $bad_l2_miss = $opt_l2_old.merge(
      nametag: "l2miss_max_old",
      :l2l3req_offset=>5,
      :l2l3resp_offset=>16,
      :membusreq_offset=>121,
      :membusresp_offset=>93,
      :mem_offset=>81
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

    $opt_l3_miss= {
      nametag: "l3_miss_opt",
      :l2l3req_tl=>7,
      :l2l3req_offset=>13,
      :l2l3resp_tl=>11,
      :l2l3resp_offset=>4,
      :membusreq_tl=>66,
      :membusreq_offset=>0,
      :membusresp_tl=>66,
      :membusresp_offset=>49,
      :mem_tl=>44,
      :mem_offset=>9
    }

    $bad_l3_miss = $opt_l3_miss.merge(
      nametag: "l3miss_max",
      :l2l3req_offset=>26,
      :l2l3resp_offset=>121,
      :membusreq_offset=>95,
      :membusresp_offset=>69,
      :mem_offset=>64
    )

    def parameter_tests
      o = $secure_opts.merge(
          num_wl: 2
      )

      # Optimized L2 Miss Path
      iterate_mp o.merge $opt_l2_miss
      iterate_mp o.merge $opt_l2_miss.merge(
        nametag: "l2miss_opt_nocwf",
        nocwf: true
      )

      # Worst L2 Miss Path
      iterate_mp o.merge $bad_l2_miss
      iterate_mp o.merge $bad_l2_miss.merge(
        nametag: "l2miss_max_nocwf",
        nocwf: true
      )

      # Optimized L3 Hit Path
      iterate_mp o.merge $opt_l3_hit
      iterate_mp o.merge $opt_l3_hit.merge(
        nametag: "l3hit_opt_nocwf",
        nocwf: true
      )

      # Worst L3 Hit Path
      iterate_mp o.merge $bad_l3_hit
      iterate_mp o.merge $bad_l3_hit.merge(
        nametag: "l3hit_max_nocwf",
        nocwf: true
      )

      # Optimized L3 Miss Path
      iterate_mp o.merge $opt_l3_miss
      iterate_mp o.merge $opt_l3_miss.merge(
        nametag: "l3miss_opt_nocwf",
        nocwf: true
      )

      # Worst L3 Miss Path
      iterate_mp o.merge $bad_l3_hit
      iterate_mp o.merge $bad_l3_hit.merge(
        nametag: "l3miss_max_nocwf",
        nocwf: true
      )

      iterate_mp o.merge(
        nametag: "nocwf",
        nocwf: true
      )
    end

end
