#------------------------------------------------------------------------------
# Performance Evaluation
#------------------------------------------------------------------------------
require_relative 'runscripts'
include RunScripts

module RunScripts
    $test_opts = {
        maxinsts: 10**3,
        fastforward: 10,
        #num_wl: 4,
        #skip2: true,
        skip6: true,
        # workloads: { 
        #     hardstride_nothing: %w[hardstride nothing],
        #     # nothing_hardstride: %w[nothing hardstride],
        #     hardstride_hardstride: %w[hardstride hardstride],
        #     # nothing_nothing: %w[nothing nothing]
        # },
        debug: true,
        runmode: :local

    }

    def single
        iterate_mp(
            scheme: "none",
            workloads: (single_prog_wl 8)
        )

        iterate_mp(
            scheme: "none",
            workloads: (single_prog_wl 6)
        )

        iterate_mp(
            scheme: "none",
            workloads: (single_prog_wl 4)
        )

        iterate_mp(
            scheme: "none",
            workloads: (single_prog_wl 2)
        )
    end

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
            num_wl: 4,
            skip2: true,
            bank_part: false,
            tl0: 44,
            tl1: 44,
            nametag: "no_part"
        )
    end

    def cache_sweep
        #1MB / Core
        iterate_mp $secure_opts.merge(
            num_wl: 4,
            skip2: true,
            cacheSize: 4,
            nametag: "4MBLLC"
        )
        #1.5MB / Core
        iterate_mp $secure_opts.merge(
            num_wl: 4,
            skip2: true,
            cacheSize: 6,
            nametag: "6MBLLC"
        )
        #2MB / core
        iterate_mp $secure_opts.merge(
            num_wl: 4,
            skip2: true,
            cacheSize: 9,
            nametag: "9MBLLC"
        )
    end

    # NOT WORKING
    def more_channels
        #2 chan
        iterate_mp $test_opts.merge(
            num_wl: 4,
            skip2: true,
            schemes: %w[2chan],
            scheme: "2chan"
        )
        iterate_mp $secure_opts.merge $test_opts.merge(
            num_wl: 8,
            skip2: true,
            skip4: true,
            skip6: true,
            schemes: %w[tp_2chan],
            scheme: "tp_2chan"
        )
        #4 chan
        iterate_mp $test_opts.merge(
            num_wl: 8,
            skip2: true,
            skip4: true,
            skip6: true,
            schemes: %w[4chan],
            scheme: "4chan"
        )
        iterate_mp $secure_opts.merge $test_opts.merge(
            num_wl: 8,
            skip2: true,
            skip4: true,
            skip6: true,
            schemes: %w[tp_4chan],
            scheme: "tp_4chan"
        )
    end

    def breakdown

      o = {
        schemes: %w[none],
        scheme: "none",
        addrpar: true,
        num_wl: 4,
        skip2: true
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
        scheme: "tp",
        bank_part: true
      )

    end

############################################################################## 
# Resource Allocation
############################################################################## 
    def ncore_2tc
      o = $secure_opts.merge(
        nametag: "2tc",
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
      # iterate_mp o.merge(
      #   num_wl: 8,
      #   skip2: true,
      #   skip4: true,
      #   skip6: true,
      #   numpids: 2,
      #   p0threadID: 0,
      #   p1threadID: 0,
      #   p2threadID: 0,
      #   p3threadID: 0,
      #   p4threadID: 1,
      #   p5threadID: 1,
      #   p6threadID: 1,
      #   p7threadID: 1
      # )

    end

    $allocation_2_core = {
        ast_ast: {},
        h264_hmm: {
            assoc_alloc: true,
            ways0: 4,
            ways1: 12,
            tl0: 25,
            tl1: 35
        },
        ast_h264: {
            assoc_alloc: true,
            ways0: 2,
            ways1: 14,
            tl0: 23,
            tl1: 30
        },
        sjg_h264: {
            assoc_alloc: true,
            ways0: 6,
            ways1: 10,
            tl0: 30,
            tl1: 23
        },
        sjg_sgj: {},
        mcf_ast: {
            assoc_alloc: true,
            ways0: 14,
            ways1: 2,
            tl0: 200,
            tl1: 23
        },
        lib_ast: {
            assoc_alloc: true,
            ways0: 14,
            ways1: 2,
            tl0: 200,
            tl1: 23
        },
        mcf_mcf: {},
        mcf_lib: {
            assoc_alloc: true,
            ways0: 12,
            ways1: 4,
            tl0: 43,
            tl1: 43,
        },
        lib_lib: {
            tl0: 43,
            tl1: 43
        },
    }

    $allocation_4_core = {
        ast_ast: {},
        h264_hmm: {
            assoc_alloc: true,
            ways0: 2,
            ways2: 2,
            ways1: 6,
            ways3: 6,
            tl0: 25,
            tl2: 25,
            tl1: 35,
            tl3: 35
        },
        ast_h264: {
            assoc_alloc: true,
            ways0: 1,
            ways2: 1,
            ways1: 7,
            ways3: 7,
            tl0: 23,
            tl2: 23,
            tl1: 30,
            tl3: 30
        },
        sjg_h264: {
            assoc_alloc: true,
            ways0: 3,
            ways2: 3,
            ways1: 5,
            ways3: 5,
            tl0: 30,
            tl2: 30,
            tl1: 23,
            tl3: 23
        },
        sjg_sgj: {},
        mcf_ast: {
            assoc_alloc: true,
            ways0: 7,
            ways2: 7,
            ways1: 1,
            ways3: 1,
            tl0: 200,
            tl2: 200,
            tl1: 23,
            tl3: 23
        },
        lib_ast: {
            assoc_alloc: true,
            ways0: 7,
            ways2: 7,
            ways1: 1,
            ways3: 1,
            tl0: 200,
            tl2: 200,
            tl1: 23,
            tl3: 23
        },
        mcf_mcf: {},
        mcf_lib: {
            assoc_alloc: true,
            ways0: 6,
            ways2: 6,
            ways1: 2,
            ways3: 2,
            tl0: 43,
            tl1: 43,
            tl2: 43,
            tl3: 43,
        },
        lib_lib: {
            tl0: 43,
            tl1: 43,
            tl2: 43,
            tl3: 43
        },
    }

    $allocation_8_core = {
        ast_ast: {},
        h264_hmm: {
            assoc_alloc: true,
            ways0: 2,
            ways2: 2,
            ways4: 2,
            ways6: 2,
            ways1: 7,
            ways3: 7,
            ways5: 7,
            ways7: 7,
            tl0: 25,
            tl2: 25,
            tl4: 25,
            tl6: 25,
            tl1: 35,
            tl3: 35,
            tl5: 35,
            tl7: 35
        },
        ast_h264: {
            assoc_alloc: true,
            ways0: 2,
            ways2: 2,
            ways4: 2,
            ways6: 2,
            ways1: 7,
            ways3: 7,
            ways5: 7,
            ways7: 7,
            tl0: 23,
            tl2: 23,
            tl4: 23,
            tl6: 23,
            tl1: 30,
            tl3: 30,
            tl5: 30,
            tl7: 30
        },
        sjg_h264: {
            assoc_alloc: true,
            ways0: 3,
            ways2: 3,
            ways4: 3,
            ways6: 3,
            ways1: 6,
            ways3: 6,
            ways5: 6,
            ways7: 6,
            tl0: 30,
            tl2: 30,
            tl4: 30,
            tl6: 30,
            tl1: 23,
            tl3: 23,
            tl5: 23,
            tl7: 23
        },
        sjg_sgj: {},
        mcf_ast: {
            assoc_alloc: true,
            ways0: 8,
            ways2: 8,
            ways4: 8,
            ways6: 8,
            ways1: 1,
            ways3: 1,
            ways5: 1,
            ways7: 1,
            tl0: 200,
            tl2: 200,
            tl4: 200,
            tl6: 200,
            tl1: 23,
            tl3: 23,
            tl5: 23,
            tl7: 23
        },
        lib_ast: {
            assoc_alloc: true,
            ways0: 8,
            ways2: 8,
            ways4: 8,
            ways6: 8,
            ways1: 1,
            ways3: 1,
            ways5: 1,
            ways7: 1,
            tl0: 200,
            tl2: 200,
            tl4: 200,
            tl6: 200,
            tl1: 23,
            tl3: 23,
            tl5: 23,
            tl7: 23
        },
        mcf_mcf: {},
        mcf_lib: {
            assoc_alloc: true,
            ways0: 7,
            ways2: 7,
            ways4: 7,
            ways6: 7,
            ways1: 2,
            ways3: 2,
            ways5: 2,
            ways7: 2,
            tl0: 43,
            tl1: 43,
            tl2: 43,
            tl3: 43,
            tl4: 43,
            tl5: 43,
            tl6: 43,
            tl7: 43,
        },
        lib_lib: {
            tl0: 43,
            tl1: 43,
            tl2: 43,
            tl3: 43,
            tl4: 43,
            tl5: 43,
            tl6: 43,
            tl7: 43
        },
    }


    def resource_alloc
        iterate_mp $secure_opts.merge(
            num_wl: 8,
            skip6: true,
            skip2: true,
            nametag: "allocated",
            do_allocation: true,
        )
    end

    def resource_alloc_relaxed
        iterate_mp $secure_opts.merge(
            num_wl: 8,
            skip6: true,
            skip2: true,
            nametag: "allocated_relaxed",
            do_allocation: true,
            relax_dtime: true
        )
    end

    def relaxed_two_core
        iterate_mp $secure_opts.merge(
            num_wl: 2,
            nametag: "relaxed",
            relax_dtime: true
        )
    end


############################################################################## 
# Flushing
##############################################################################
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

      #[bw, rbw, iw25, iw05, iw75].product([10,50,100]).each do |o,period|
      [bw].product([1,10,50,100]).each do |o,period|
        iterate_mp o.merge(
            nametag: "flush#{period}ms_#{o[:wbtag]}",
            context_sw_freq: period * 10**9,
            do_flush: true,
            num_wl: 4,
            skip2: true,
        )
      end

    end 

    def flush_simple
        iterate_mp $secure_opts.merge $test_opts.merge(
            do_flush: true,
            context_sw_freq: (1 * 10**9),
            nametag: "flush",
        )
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
