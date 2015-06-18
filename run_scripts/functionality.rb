#------------------------------------------------------------------------------
# Security Tests
#------------------------------------------------------------------------------
require_relative 'runscripts'
require_relative 'performance'
require 'colored'
include RunScripts

module RunScripts

    # $test_opts = {
    #     maxinsts: 10**5,
    #     fastforward: 10,
    #     num_wl: 8,
    #     skip2: true,
    #     skip6: true,
    #     workloads: { 
    #         hardstride_nothing: %w[hardstride nothing],
    #         # nothing_hardstride: %w[nothing hardstride],
    #         hardstride_hardstride: %w[hardstride hardstride],
    #         # nothing_nothing: %w[nothing nothing]
    #     },
    #     debug: true,
    #     runmode: :local

    # }

    def test_baseline
        iterate_mp $test_opts.merge(
            scheme: "none",
        )
    end

    def test_secure
        iterate_mp $test_opts.merge $secure_opts.merge(
            {}
        )
    end

    def test_only_mc
        iterate_mp $test_opts.merge(
            nametag: "only_mc",
            schmes: %w[tp],
            addrpar: true
        )
    end

    def test_only_rrbus
        iterate_mp $test_opts.merge(
            nametag: "only_rrbus",
            rr_nc: true,
            split_rport: true
        )
    end

    def test_only_waypart
        iterate_mp $test_opts.merge(
            nametag: "only_waypart",
            waypart: true
        )
    end

    def test_2tc
        # # 4 cores
        iterate_mp $test_opts.merge $secure_opts.merge(
            nametag: "2tc",
            num_wl: 4,
            skip2: true,
            numpids: 2,
            p0threadID: 0,
            p1threadID: 0,
            p2threadID: 1,
            p3threadID: 1
        )

        # 6 cores
        # iterate_mp $test_opts.merge(
        #     nametag: "2tc",
        #     num_wl: 6,
        #     skip2: true,
        #     skip4: true,
        #     p0threadID: 0,
        #     p1threadID: 0,
        #     p2threadID: 0,
        #     p3threadID: 1,
        #     p4threadID: 1,
        #     p5threadID: 1
        # )
        
        # 8 cores
        iterate_mp $test_opts.merge $secure_opts.merge(
            nametag: "2tc",
            scheme: "tp",
            num_wl: 8,
            skip2: true,
            skip4: true,
            skip6: true,
            numpids: 4,
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

end
