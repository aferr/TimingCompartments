#!/usr/bin/ruby
require_relative 'runscripts'
include RunScripts

module RunScripts
def rerun
    gem5home = Dir.new(Dir.pwd)
    %w[
        run_2tc_tp_4cpus_hhn
        run_2tc_tp_4cpus_hhnr
        run_2tc_tp_4cpus_hmd
        run_2tc_tp_4cpus_hmdr
        run_2tc_tp_4cpus_lld
        run_2tc_tp_4cpus_mmi
        run_2tc_tp_6cpus_hhd
        run_2tc_tp_6cpus_hhdr
        run_2tc_tp_6cpus_hhn
        run_2tc_tp_6cpus_hhnr
        run_2tc_tp_6cpus_hmd
        run_2tc_tp_6cpus_hmdr
        run_2tc_tp_6cpus_mmi
        run_2tc_tp_8cpus_hhd
        run_2tc_tp_8cpus_hhdr
        run_2tc_tp_8cpus_hhn
        run_l2miss_max_nocwf_tp_2cpus_hhn
        run_l2miss_max_nocwf_tp_2cpus_hhnr
        run_l2miss_max_nocwf_tp_2cpus_hmd
        run_l2miss_max_nocwf_tp_2cpus_hmdr
        run_l2miss_max_nocwf_tp_2cpus_mmi
        run_l2miss_max_tp_2cpus_hhn
        run_l2miss_max_tp_2cpus_hhnr
        run_l2miss_max_tp_2cpus_hmd
        run_l2miss_max_tp_2cpus_hmdr
        run_l2miss_max_tp_2cpus_mmi
        run_l3hit_max_nocwf_tp_2cpus_hhi
        run_l3hit_max_nocwf_tp_2cpus_hhn
        run_l3hit_max_nocwf_tp_2cpus_hhnr
        run_l3hit_max_nocwf_tp_2cpus_hlir
        run_l3hit_max_nocwf_tp_2cpus_hmd
        run_l3hit_max_nocwf_tp_2cpus_hmdr
        run_l3hit_max_nocwf_tp_2cpus_hmir
        run_l3hit_max_nocwf_tp_2cpus_lld
        run_l3hit_max_nocwf_tp_2cpus_lli
        run_l3hit_max_nocwf_tp_2cpus_mmd
        run_l3hit_max_nocwf_tp_2cpus_mmi
        run_l3hit_max_tp_2cpus_hhn
        run_l3hit_max_tp_2cpus_hhnr
        run_l3hit_max_tp_2cpus_hmd
        run_l3hit_max_tp_2cpus_hmdr
        run_l3hit_max_tp_2cpus_lld
        run_l3hit_max_tp_2cpus_mmi
        run_l3hit_opt_nocwf_tp_2cpus_hhn
        run_l3hit_opt_nocwf_tp_2cpus_hhnr
        run_l3hit_opt_nocwf_tp_2cpus_hmd
        run_l3hit_opt_nocwf_tp_2cpus_hmdr
        run_l3hit_opt_nocwf_tp_2cpus_lld
        run_l3hit_opt_nocwf_tp_2cpus_mmi
        run_l3hit_opt_tp_2cpus_hhn
        run_l3hit_opt_tp_2cpus_hhnr
        run_l3hit_opt_tp_2cpus_hmd
        run_l3hit_opt_tp_2cpus_hmdr
        run_l3hit_opt_tp_2cpus_lld
        run_l3hit_opt_tp_2cpus_mmi
        run_l3miss_opt_nocwf_tp_2cpus_hhn
        run_l3miss_opt_tp_2cpus_hhn
        run_l3miss_opt_tp_2cpus_hldr
        run_l3miss_opt_tp_2cpus_hlir
        run_l3miss_opt_tp_2cpus_hmd
        run_none_6cpus_hmir
        run_none_6cpus_llir
        run_only_mc_tp_2cpus_hmd
        run_only_rrbus_none_2cpus_hhn
        run_only_rrbus_none_2cpus_hhnr
        run_only_rrbus_none_2cpus_hld
        run_only_rrbus_none_2cpus_hmd
        run_only_rrbus_none_2cpus_hmdr
        run_only_rrbus_none_2cpus_lld
        run_only_rrbus_none_2cpus_mmi
        run_only_waypart_none_2cpus_hhn
        run_only_waypart_none_2cpus_hhnr
        run_only_waypart_none_2cpus_hld
        run_only_waypart_none_2cpus_hmd
        run_only_waypart_none_2cpus_hmdr
        run_only_waypart_none_2cpus_lld
        run_only_waypart_none_2cpus_mmi
        run_tp_2cpus_hhn
        run_tp_2cpus_hhnr
        run_tp_2cpus_hld
        run_tp_2cpus_hmd
        run_tp_2cpus_hmdr
        run_tp_2cpus_lld
        run_tp_2cpus_mmi
        run_tp_4cpus_hhn
        run_tp_4cpus_hhnr
        run_tp_4cpus_hmd
        run_tp_4cpus_hmdr
        run_tp_4cpus_mmi
        run_tp_6cpus_hhn
        run_tp_6cpus_hhnr
        run_tp_6cpus_hmd
    ].each do |experiment|
        File.open(Dir.pwd+"/scriptgen/"+experiment) {|file|
            exp_abspath = File.expand_path file
            system "qsub -wd #{gem5home.path} -e stderr/ -o stdout/ #{exp_abspath}"
        }
    end
end
end
