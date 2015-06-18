#------------------------------------------------------------------------------
# Performance Evaluation
#------------------------------------------------------------------------------
require_relative 'runscripts'
include RunScripts

module RunScripts
    $test_opts = {
        maxinsts: 10**5,
        fastforward: 10,
        num_wl: 4,
        skip2: true,
        skip6: true,
        workloads: { 
            hardstride_nothing: %w[hardstride nothing],
            # nothing_hardstride: %w[nothing hardstride],
            hardstride_hardstride: %w[hardstride hardstride],
            # nothing_nothing: %w[nothing nothing]
        },
        debug: true,
        runmode: :local

    }

    def baseline
      iterate_mp(
        scheme: "none",
        num_wl: 8,
      )
    end
    
    def ncore_ntc
      iterate_mp $secure_opts.merge(
        num_wl: 8,
      )
    end

    def ncore_ntc_no_part
        iterate_mp $secure_opts.merge(
            num_wl: 8,
            bank_part: false,
            tl0: 44,
            tl1: 44,
            nametag: "no_part"
        )
    end

    def breakdown

      o = {
        schemes: %w[none],
        scheme: "none",
        addrpar: true,
        num_wl: 4,
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
        nametag: "2tc",
        runmode: :fake
      )

      # 4 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 4,
        skip2: true,
        numpids: 2,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 1,
        p3threadID: 1
      )

      # 8 Cores 2 TCs
      iterate_mp o.merge(
        num_wl: 8,
        skip2: true,
        skip4: true,
        skip6: true,
        numpids: 2,
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
        reserve_flush: false
      )

      #Reserved Bandwidth Writeback
      rbw = $secure_opts.merge(
          wbtag: "rbw",
          reserve_flush: true
      )

      #Insecure Writeback
      iw25, iw05, iw75 = [0.25,0.5,0.75].map do |r|
        {
          wbtag: "iw#{r.to_s.sub(/\./,'')}",
          flushRatio: r
        }
      end

      [bw, rbw, iw25, iw05, iw75].product([10,50,100]).each do |o,period|
        iterate_mp o.merge(
            nametag: "flush#{period}ms_#{o[:wbtag]}",
            context_sw_freq: period * 10**10,
            do_flush: true,
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
      :tl0=>52,
      :tl1=>52,
      :dramoffset=>45
    }

    $opt_l2_old = {
      nametag: "l2miss_opt_old",
      :l2l3req_tl=>4,
      :l2l3req_offset=>2,
      :l2l3resp_tl=>11,
      :l2l3resp_offset=>18,
      :membusreq_tl=>66,
      :membusreq_offset=>66,
      :membusresp_tl=>66,
      :membusresp_offset=>39,
      :tl0=>44,
      :tl1=>44,
      :dramoffset=>7
    }

    #Maximized based on old optimum. Could not collect with new optimum.
    $bad_l2_miss = $opt_l2_old.merge(
      nametag: "l2miss_max",
      :l2l3req_offset=>5,
      :l2l3resp_offset=>16,
      :membusreq_offset=>121,
      :membusresp_offset=>93,
      :dramoffset=>81
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
      nametag: "l3miss_opt",
      :l2l3req_tl=>7,
      :l2l3req_offset=>13,
      :l2l3resp_tl=>11,
      :l2l3resp_offset=>4,
      :membusreq_tl=>66,
      :membusreq_offset=>0,
      :membusresp_tl=>66,
      :membusresp_offset=>49,
      :tl0=>44,
      :tl1=>44,
      :dramoffset=>9
    }

    $bad_l3_miss = $opt_l3_miss.merge(
      nametag: "l3miss_max",
      :l2l3req_offset=>26,
      :l2l3resp_offset=>121,
      :membusreq_offset=>95,
      :membusresp_offset=>69,
      :dramoffset=>64
    )

    def parameter_tests
      o = $secure_opts.merge(
          num_wl: 2,
      )

      # Optimized L2 Miss Path
      iterate_mp o.merge $opt_l2_miss

      # Worst L2 Miss Path
      iterate_mp o.merge $bad_l2_miss

      # Optimized L3 Hit Path
      iterate_mp o.merge $opt_l3_hit

      # Worst L3 Hit Path
      iterate_mp o.merge $bad_l3_hit

      # Optimized L3 Miss Path
      iterate_mp o.merge $opt_l3_miss

      # Worst L3 Miss Path
      iterate_mp o.merge $bad_l3_miss

    end

end
