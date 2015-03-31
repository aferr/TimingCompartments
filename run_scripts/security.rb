#------------------------------------------------------------------------------
# Security Tests
#------------------------------------------------------------------------------
require_relative "runscripts"
include RunScripts

module RunScripts

    def cache_security
        opts = {
            maxinsts: 10**3,
            fastforward: 0,
            savetraces: true,
            schemes: %w[ none tp ]
        }
        parallel_local opts

    end

    def execution_time_compare
        opts = {
            schemes: %w[ none ],
            benchmarks: $specint - %w[ bzip2 ],
            cpus: %w[detailed],
            maxinsts: 10**5,
            fastforward: 0,
        }
        #parallel_local opts

        opts = opts.merge({
            schemes: %w[ tp ],
            setpart: true,
            addrpar: true,
            split_mshr: true,
            rr_nc: true,
            debug: true,
        })
        parallel_local opts
    end

    def execution_time_memdebug
      qsub_fast(
        schemes: %w[tp],
        addrpar: true,
        maxinsts: 10**8,
        fastforward: 0,
        config: "debug/memdebug.py",
        nametag: "memdebug"
      )
    end

    def execution_time_memdebug
      qsub_fast(
        schemes: %w[none],
        rr_nc: true,
        maxinsts: 10**8,
        fastforward: 0,
        config: "debug/busdebug.py",
        nametag: "busdebug"
      )
    end

    def setpart_vs_private
        opts = {
            l3config: "private",
            benchmarks:$specint - %w[ bzip2 ],
            schemes: %w[ tp ],
            maxinsts: 10**6,
            fastforward: 0,
            addrpar: true,
            rr_nc: true,
            cpus: %w[detailed],
            result_dir: "results_private"
        }
        parallel_local opts

        opts = opts.merge({
            l3config: "shared",
            split_mshr: true,
            setpart: true,
            result_dir: "res lts_setpar"
        })

        parallel_local opts
    end

    def execution_time_compare_qsub
        opts = {
            benchmarks:$specint - %w[ bzip2 ],
            schemes: %w[ none ],
            cpus: %w[detailed],
            fastforward: 0,
        }
        #qsub_fast opts

        # set partitioning
        opts = opts.merge({
            schemes: %w[ tp ],
            setpart: true,
            addrpar: true,
            split_mshr: true,
            split_rport: true,
            rr_nc: true,
        })
        #qsub_fast opts

        # way partitioning
        opts = opts.merge({
            waypart: true,
        })
        qsub_fast opts
    end

    def security_debug
        opts = {
            nametag: "debug_traces",
            p1: "astar",
            maxinsts: 5*10**7,
            fastforward: 0,
            waypart: true,
            rr_nc: true,
            split_mshr: true,
            split_rport: true,
            addrpar: true,
            #memdebug: true,
            #runmode: :qsub,
            do_cache_trace: true,
            do_bus_trace: true,
            do_mem_trace: true,
        }
        fork do 
          if block_given? 
              yield opts.merge( p0: "gcc" )
          else
              sav_script( "detailed", "tp", "gobmk", opts )
          end
        end
        fork do
          opts = opts.merge( { p1: "gcc" } )
          if block_given?
              yield opts.merge( p0: "gcc" )
          else
              sav_script( "detailed", "tp", "gobmk", opts )
          end
        end
    end

    def paddr_test
        security_debug{ |opts|
            sav_script( "detailed", "tp", opts[:p0],
               opts.merge( maxinsts: 10**5 , nametag: "paddr_test" ) )
        }
    end

end
