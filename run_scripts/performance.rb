#------------------------------------------------------------------------------
# Performance Evaluation
#------------------------------------------------------------------------------
require_relative 'runscripts'
include RunScripts

module RunScripts

    $secure_opts = {
      schemes: %w[tp],
      addrpar: true,
      rr_nc: true,
      use_way_part: true,
      split_mshr: true,
      split_rport: true
    }

    def baseline
      qsub_scaling(
        schemes: %w[none],
        cpus: %w[detailed],
        otherbench: $specint,
        maxinsts: 10**9
      )
    end

    def baseline_nocwf
      qsub_scaling(
        schemes: %w[none],
        cpus: %w[detailed],
        otherbench: %w[astar mcf],
        nocwf: true
      )
    end

    def scalability_qsub
        qsub_scaling $secure_opts.merge(
          maxinsts: 10**9
        )
    end

    def scalability_local
     parallel_local_scaling $secure_opts.merge(
       maxinsts: 10**3,
       fastforward: 100,
       debug: true
     ) 
    end

    def breakdown

      qsub_fast(
        maxinsts: 10**9,
        nametag: "only_l2l3",
        addrpar: true,
        rr_l2l3: true,
        split_rport: true,
        schemes: %w[none]
      )

      qsub_fast(
        maxinsts: 10**9,
        nametag: "only_membus",
        addrpar: true,
        rr_mem: true,
        split_mshr: true,
        schemes: %w[none]
      )

      qsub_fast(
        maxinsts: 10**9,
        nametag: "only_waypart",
        addrpar: true,
        waypart: true,
        schemes: %w[none]
      )

      qsub_fast(
        maxinsts: 10**9,
        nametag: "only_mc",
        addrpar: true,
        schemes: %w[tp]
      )

    end

    # Obselete
    ## def coordination
    ##   qsub_scaling $secure_opts.merge(
    ##     maxinsts: 10**9,
    ##     coordination: true,
    ##     nametag: "coordinated",
    ##   )
    ## end

    def double_tc
      qsub_scaling $secure_opts.merge(
        maxinsts: 10**9,
        nametag: "double_tc",
        benchmarks: %w[mcf libquantum],
        otherbench: $specint - %w[mcf libquantum],
        skip2: true,
        skip3: true,
        numcpus: 4,
        numpids: 2,
        p0threadID: 0,
        p1threadID: 0,
        p2threadID: 1,
        p3threadID: 1
      )
    end

    def flush_overhead
      [$secure_opts, $insecure_opts].each do |opt|
        o = opt.merge(
          maxinsts: 10**3,
          fastforward: 100,
          do_flush: true,
          debug: true
        )
        puts o.to_s.green
        #1 ms
        parallel_local o.merge(nametag: "flush1ms", context_sw_freq: 10**6)
        #10 ms
        parallel_local o.merge(nametag: "flush10ms", context_sw_freq: 10**7)
        #100 ms
        parallel_local o.merge(nametag: "flush100ms", context_sw_freq: 10**8)
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
