#!/usr/bin/ruby

require 'fileutils'
require 'colored'

module RunScripts
#directories
$gem5home = Dir.new(Dir.pwd)
$specint_dir = ("benchmarks/spec2k6bin/specint")
$specfp_dir = ("benchmarks/spec2k6bin/specfp")
$synthbench_dir = ("benchmarks/synthetic")
$scriptgen_dir = Dir.new(Dir.pwd+"/scriptgen")

#Gem5 options
$fastforward = 10**9
#$fastforward = 10**5
$maxinsts = 10**8
#$maxinsts = 10**5
$maxtick = 2*10**15 
$cpus = %w[detailed] #timing is also available
$cacheSizes = [0,1,2,4]
$p0periods = [64,96,128,192,256]
$l3configs = %w[shared private]

#dramsim options
$device = "DDR3_micron_16M_8B_x8_sg15.ini"
$schemes = %w[tp none fa]
$turnlengths = [0] + (7..9).to_a
$p0periods = [64,96,128,192,256]

# Workload Characterization
# Have phases: bzip2, gcc, gobmk, h264ref
# No phases: mcf, xalan
# Cache independent: astar, libquantum, sjeng
# L2 misses over 2B instructions

# MP2BI
# mcf
# 8.368790e+07
# xalan
# 2.199928e+07
# bzip2
# 2.120806e+07
# libquantum
# 1.454017e+07
# sjeng
# 8.992062e+06
# gcc
# 7.115132e+06
# gobmk
# 5.433310e+06
# hmmer
# 4.309481e+06
# h264ref
# 1.235817e+06
# astar
# 9.910000e+02


#Multiprogram Workloads
$mpworkloads = {
  # integer workloads
  mcf_bz2: %w[ mcf bzip2 ],
  mcf_xln: %w[ mcf xalan ],
  mcf_mcf: %w[ mcf mcf ],
  mcf_lib: %w[mcf libquantum],
  mcf_ast: %w[mcf astar],
  lib_lib: %w[ libquantum libquantum],
  lib_ast: %w[ libquantum astar ],
  mcf_h264: %w[ mcf h264ref ],
  lib_sjg: %w[ libquantum sjeng ],
  sjg_sgj: %w[ sjeng sjeng ],
  ast_h264: %w[ astar h264ref ],
  h264_hmm: %w[ h264ref hmmer ],
  ast_ast: %w[ astar astar],
  bz2_h264: %w[bzip2 h264ref],
  lib_gob: %w[libquantum gobmk],
  sjg_gob: %w[sjeng gobmk],
  sjg_h264: %w[sjeng h264ref],

  # Float workloads
  # milc_milc: %w[milc milc],
  # namd_namd: %w[namd namd],
  # deal_deal: %w[dealII dealII],
  # splx_splx: %w[soplex soplex],
  # pov_pov: %w[povray povray],
  # lbm_lbm: %w[lbm lbm],
  # spx_spx: %w[sphinx3 sphinx3]

}

def single_prog_wl n
    $specint.inject({}) do |hash, name|
        hash[name] = [name] + (%w[nothing] * (n - 1)); hash
    end
end

def workloads_of_size n, wl2=$mpworkloads
  wl2.keys.inject({}) do |hash, name|
    hash[name] = n.times.inject([]) { |wl, i| wl << wl2[name][i%2]; wl }
    hash
  end
end

# Full Protection Options
$secure_opts = {
  schemes: %w[tp],
  scheme: "tp", 
  addrpar: true,
  rr_nc: true,
  waypart: true,
  split_mshr: true,
  split_rport: true,
  bank_part: true,
}

#benchmarks
$specinvoke = { 
   #"perlbench"  => "'#{$specint_dir}/perlbench -I#{$specint_dir}/perldepends -I#{$specint_dir}/lib #{$specint_dir} pack.pl'",
   "bzip2"      => "'#{$specint_dir}/bzip2 #{$specint_dir}/input.source 280'",
   "gcc"        => "'#{$specint_dir}/gcc #{$specint_dir}/200.in -o results/200.s'",
   "mcf"        => "'#{$specint_dir}/mcf #{$specint_dir}/inp.in'",
   "gobmk"      => "'#{$specint_dir}/gobmk --quiet --mode gtp --gtp-input #{$specint_dir}/13x13.tst'",
   "hmmer"      => "'#{$specint_dir}/hmmer #{$specint_dir}/nph3.hmm #{$specint_dir}/swiss41'",
   "sjeng"      => "'#{$specint_dir}/sjeng #{$specint_dir}/ref.txt'",
   "libquantum" => "'#{$specint_dir}/libquantum 1397 8'",
   "h264ref"    => "'#{$specint_dir}/h264ref -d #{$specint_dir}/foreman_ref_encoder_baseline.cfg'",
   #"omnetpp"    => "'#{$specint_dir}/omnetpp #{$specint_dir}/omnetpp.ini'",
   "astar"      => "'#{$specint_dir}/astar #{$specint_dir}/BigLakes2048.cfg'",
   "xalan"      => "'#{$specint_dir}/Xalan -v #{$specint_dir}/t5.xml #{$specint_dir}/xalanc.xsl'"  
}
$specint = $specinvoke.keys.sort

$synthinvoke = {
    "hardstride" => "#{$synthbench_dir}/hardstride",
    "nothing"     => "#{$synthbench_dir}/nothing"
}
$synthb = $synthinvoke.keys.sort

$specfpinvoke = {
    # "bwaves"     => "'#{$specfp_dir}/bwaves'",
    # "gamess"     => "'#{$specfp_dir}/gamess < #{$specfp_dir}/cytosine.2.config'",
    "milc"       => "'#{$specfp_dir}/milc < #{$specfp_dir}/su3imp.in'",
    # "zeusmp"     => "'#{$specfp_dir}/zeusmp'",
    # "gromacs"    => "'#{$specfp_dir}/gromacs -silent -deffnm #{$specfp_dir}/gromacs -nice 0'",
    # "cactusADM"  => "'#{$specfp_dir}/cactusADM #{$specfp_dir}/benchADM.par'",
    # "leslie3d"   => "'#{$specfp_dir}/leslie3d < #{$specfp_dir}/leslie3d.in'",
    "namd"       => "'#{$specfp_dir}/namd --input #{$specfp_dir}/namd.input --iterations 38 --output #{$specfp_dir}/namd.out'",
    "dealII"     => "'#{$specfp_dir}/dealII 23'",
    "soplex"     => "'#{$specfp_dir}/soplex -sl -e -m45000 #{$specfp_dir}/pds-50.mps'",
    "povray"     => "'#{$specfp_dir}/povray #{$specfp_dir}/SPEC-benchmark-ref.ini'",
    # "calculix"   => "'#{$specfp_dir}/calculix -i #{$specfp_dir}/hyperviscoplastic.inp'",
    # "GemsFDTD"   => "'#{$specfp_dir}/GemsFDTD'",
    # "tonto"      => "'#{$specfp_dir}/tonto'",
    "lbm"        => "'#{$specfp_dir}/lbm 3000 reference.dat 0 0 #{$specfp_dir}/100_100_130_ldc.of'",
    # "wrf"        => "'#{$specfp_dir}/wrf'",
    "sphinx3"    => "'#{$specfp_dir}/sphinx_livepretend ctlfile . #{$specfp_dir}/args.an4'"  
}
$specfp = $specfpinvoke.keys.sort

def invoke( name )
    $specinvoke[name] || $synthinvoke[name] || $specfpinvoke[name]
end

def sav_script( options = {} ) 

    options = {
        tl0: 23,
        tl1: 23,
        l3config: "shared",
        runmode: :qsub,
        maxinsts: $maxinsts,
        fastforward: $fastforward,
        result_dir: "results",
        cpu: "detailed",
        scheme: "none",
    }.merge options

    cpu = options[:cpu]
    scheme = options[:scheme]

    # workloads to run on p1-p3
    p0         = options[:p0]
    p1         = options[:p1]
    p2         = options[:p2]
    p3         = options[:p3]
    # turn length for p0-p3. Assumed equal unless diffperiod is supplied. The 
    # turn length is 2**arg unless diffperiod is supplied, otherwise it is arg.
    tl0        = options[:tl0]
    tl1        = options[:tl1]
    # Results directory
    result_dir = options[:result_dir]
    # allows the turn lengths for p0-p3 to differ
    diffperiod = options[:diffperiod]
    # shared or private l3
    l3config   = options[:l3config]
    # runmode can be qsub: to submit jobs, local: to run the test locally, or 
    # none: to generate the scripts without running them
    runmode    = options[:runmode]
    # maximum number of instructions
    maxinsts   = options[:maxinsts]
    # number of instructions to fastforward,
    # 0 removes --fastforward from the script
    fastforward= options[:fastforward]
    # Should L3 be set partitioned?
    use_set_part = options[:setpart]
    # Should L3 be way partitioned?
    use_way_part = options[:waypart]
    # Use a round robin noncoherent bus
    rr_nc        = options[:rr_nc]
    # Determines if trace files for security should be saved
    savetraces = options[:savetraces]
    # Determines l3 trace file output.
    l3tracefile= options[:l3tracefile]
    # Produce Gem5 builtin cache traces
    cacheDebug = options[:cacheDebug]
    # Produce Gem5 builtin MMU traces
    mmuDebug   = options[:mmuDebug]
    # Use gem5.debug instead of gem5.fast
    debug = options[:debug] ||
        options[:cacheDebug] ||
        options[:gdb] ||
        options[:memdebug] ||
        options[:mmuDebug]

    options[:otherbench] = options[:benchmarks] if options[:otherbench].nil?

    numcpus = options[:numcpus] = (
        n = 0
        until eval "options[:p#{n}].nil?"
          n += 1
        end; n
    )

    cacheSize  = options[:cacheSize] || lambda { |x|
        x >= 8 ? 9 :
        x >= 6 ? 6 :
        x >= 4 ? 4 :
        2
    }.call(numcpus)

    o = options

    filename = "#{scheme}_#{numcpus}cpus_#{p0}_#{p1}"
    filename = "#{scheme}_#{numcpus}cpus_#{o[:wl_name]}" unless o[:wl_name].nil?

    filename = "#{options[:nametag]}_"+filename if options[:nametag]
    filename = options[:filename] unless options[:filename].nil?
  
    FileUtils.mkdir_p( result_dir ) unless File.directory?( result_dir )

    script = File.new($scriptgen_dir.path+"/run_#{filename}","w+")
    script.puts("#!/bin/bash")
    script.puts("build/ARM/gem5.fast \\") unless debug
    script.puts("build/ARM/gem5.debug \\") if debug 
    script.puts("--remote-gdb-port=0 \\")
    script.puts("--debug-flags=Cache \\") if cacheDebug
    script.puts("--debug-flags=MMU \\") if mmuDebug
    script.puts("--debug-flags=Bus,MMU,Cache\\") if options[:memdebug]
    script.puts("    --stats-file=#{filename}_stats.txt \\")
    script.puts("    configs/#{options[:config] || "dramsim2/dramsim2_se.py"} \\")
    script.puts("    --numcpus=#{options[:numcpus]} \\")
    script.puts("    --cpu-type=#{cpu} \\")
    script.puts("    --caches \\")
    script.puts("    --l2cache \\")
    unless cacheSize == 0
        script.puts("    --l3cache \\")
        script.puts("    --l3_size=#{cacheSize}MB\\")
        script.puts("    --l3config=#{l3config} \\")
    end
    script.puts("    --fast-forward=#{fastforward} \\") unless fastforward == 0
    script.puts("    --maxinsts=#{maxinsts} \\")
    script.puts("    --maxtick=#{$maxtick} \\")
    script.puts("    --nocwf \\") if options[:nocwf]

    #Protection Mechanisms
    script.puts("    --bank_part \\")     if options[:bank_part]
    script.puts("    --fixaddr \\")       if scheme == "fa" || options[:addrpar]
    script.puts("    --rr_nc \\" )        if rr_nc
    script.puts("    --rr_l2l3 \\")       if options[:rr_l2l3]
    script.puts("    --rr_mem \\")        if options[:rr_mem]
    script.puts("    --use_set_part \\" ) if use_set_part
    script.puts("    --use_way_part \\")  if use_way_part
    script.puts("    --split_mshr \\")    if options[:split_mshr]
    script.puts("    --split_rport \\")   if options[:split_rport]
    script.puts("    --do_flush \\")      if options[:do_flush]
    script.puts("    --reserve_flush \\") if options[:reserve_flush]
    script.puts("    --flushRatio=#{options[:flushRatio]} \\") unless options[:flushRatio].nil?
    cswf = options[:context_sw_freq]
    script.puts("    --context_sw_freq=#{cswf}\\" ) unless cswf.nil?

    #Time Quanta and Offsets
    [
      :l2l3req_tl,
      :l2l3req_offset,
      :l2l3resp_tl,
      :l2l3resp_offset,
      :membusreq_tl,
      :membusreq_offset,
      :membusresp_tl,
      :membusresp_offset,
      :dramoffset
    ].each do |param|
      unless options[param].nil?
       script.puts("    --#{param.to_s} #{options[param]} \\")
      end
    end

    #Cache allocation
    script.puts("   --assoc_fair \\") if options[:assoc_alloc].nil?

    #Security Policy
    options[:numpids] = options[:numcpus] if options[:numpids].nil?
    script.puts("    --numpids=#{options[:numpids]} \\")
    (0..7).each do |i|
      param = "p#{i}threadID".to_sym
      options[param].nil? ?
        script.puts("    --#{param.to_s} #{i}\\") :
        script.puts("    --#{param.to_s} #{options[param]}\\") 
    end

    #Trace Options
    script.puts("    --do_cache_trace \\") if options[:do_cache_trace]
    l3tracefile  = l3tracefile || "#{result_dir}/l3trace_#{filename}.txt"
    script.puts("    --l3tracefile #{l3tracefile}\\") if options[:do_cache_trace]
    script.puts("    --do_bus_trace \\"  ) if options[:do_bus_trace]
    membustracefile = options[:bus_trace_file] || "#{result_dir}/membustrace_#{filename}.txt"
    l2l3bustracefile = options[:bus_trace_file] || "#{result_dir}/l2l3bustrace_#{filename}.txt"
    script.puts("    --membustracefile #{membustracefile}\\") if options[:do_bus_trace]
    script.puts("    --l2l3bustracefile #{l2l3bustracefile}\\") if options[:do_bus_trace]
    script.puts("    --do_mem_trace \\"  ) if options[:do_mem_trace]
    memtracefile = options[:mem_trace_file] || "#{result_dir}/memtrace_#{filename}.txt"
    script.puts("    --mem_trace_file #{memtracefile}\\") if options[:do_mem_trace]
    l2tracefile  = options[:l2tracefile] || "#{result_dir}/l2trace_#{filename}.txt"
    script.puts("    --l2tracefile #{l2tracefile}\\") if options[:do_cache_trace]

    script.puts("    --dramsim2 \\")
    #script.puts("    --tpturnlength=#{tl0} \\") unless tl0==0 || diffperiod
    script.puts("    --devicecfg="+
                "./ext/DRAMSim2/ini/#{$device} \\")
    if tl0== 0
        script.puts("    --systemcfg=./ext/DRAMSim2/system_ft.ini \\")
    else
        script.puts("    --systemcfg=./ext/DRAMSim2/system_#{scheme}.ini \\")
    end
    script.puts("    --outputfile=/dev/null \\")

    numcpus.times do |n|
      script.puts "    --p#{n}=#{invoke(options[eval ":p#{n}"])} \\"
    end

    script.puts("   --diffperiod \\")
    script.puts("   --p0period=#{tl0} \\")
    script.puts("   --p1period=#{tl1} \\")

    script.puts("    >! #{result_dir}/stdout_#{filename}.out")
    script_abspath = script.path
    script.close


    FileUtils.mkdir_p( "stderr" ) unless File.directory?( "stderr" )
    FileUtils.mkdir_p( "stdout" ) unless File.directory?( "stdout" )
    

    if runmode == :qsub
      sleep(1)
      success = system "qsub -wd #{$gem5home.path} -e stderr/ -o stdout/ #{script_abspath}"
    end
    puts "#{filename}".magenta
    success = system "sh #{script_abspath}" if runmode == :local
    [success,filename]
end

# def single opts={}
#     o = {
#         cpu: "detailed",
#         schemes: %w[ none],
#         scheme: "none",
#         benchmarks: $specint,
#         threads: 1
#     }.merge opts
# 
#     o[:benchmarks].each do |b|
#         [4,6,9].each do |c|
#             sav_script o.merge(
#                 nametag: "#{c}mb",
#                 p0: b,
#                 cacheSize: c)
#         end
#         sav_script o.merge(p0: b)
#     end
# 
# end


def iterate_mp o={}
  o = {
    num_wl: 2,
    skip3: true,
    skip5: true,
    skip7: true
  }.merge o

  2.upto(o[:num_wl]) do |n|
    wls = o[:workloads].nil? ?
        (workloads_of_size n) :
        o[:workloads]
    wls.keys.each do |wl|
      p = o.merge(wl_name: wl)
      wls[wl].each_with_index do |benchmark,i|
        p = p.merge( "p#{i}".to_sym => benchmark )
      end
      sav_script p unless eval("o[:skip#{n}]")
    end
  end

end

end
