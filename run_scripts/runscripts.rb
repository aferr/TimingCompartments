#!/usr/bin/ruby

require 'fileutils'
require 'colored'

module RunScripts
#directories
$gem5home = Dir.new(Dir.pwd)
$specint_dir = (Dir.pwd+"/benchmarks/spec2k6bin/specint")
$scriptgen_dir = Dir.new(Dir.pwd+"/scriptgen")

#Gem5 options
$fastforward = 10**9
$maxinsts = 10**8
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
  hhd: %w[ mcf bzip2 ],
  hhn: %w[ mcf xalan ],
  hhi: %w[ libquantum libquantum],
  hli: %w[ libquantum astar ],
  hld: %w[ mcf h264ref ],
  hmi: %w[ libquantum sjeng ],
  hmd: %w[ xalan gcc ],
  mmi: %w[ gcc gobmk ],
  mmd: %w[ sjeng sjeng ],
  llp: %w[ astar h264ref ],
  lld: %w[ h264ref hmmer ],
  lli: %w[ astar astar]
}

def workloads_of_size n, wl2=$mpworkloads
  wl2.keys.inject({}) do |hash, name|
    hash[name] = n.times.inject([]) { |wl, i| wl << wl2[name][i%2]; wl }
    hash
  end
end

def rotated_workloads wls
  wls.keys.inject({}) do |rwls,wl|
    b = wls[wl]
    rwls[(wl.to_s+'r').to_sym] = [b[1],b[0],b[2..b.size-1]].flatten
    rwls
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
  split_rport: true
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
    "hardstride1" => "#{$synthbench_dir}hardstride -d #{$duration} -p 1",
    "randmem1"    => "#{$synthbench_dir}randmem -d #{$duration} -p 1",
    #"randmem10"   => "#{$synthbench_dir}randmem -d #{$duration} -p 10",
    #"randmem100"  => "#{$synthbench_dir}randmem -d #{$duration} -p 100",
    "nothing"     => "#{$synthbench_dir}nothing"
}
$synthb = $synthinvoke.keys.sort

def invoke( name )
    $specinvoke[name] || $synthinvoke[name]
end

def sav_script( options = {} ) 

    options = {
        cacheSize: 4,
        #TP Minimum: 
        tl0: 64,
        tl1: 64,
        tl2: 64,
        tl3: 64,
        #FA Minimum:
        # tl0: 18,
        # tl1: 18,
        # tl2: 18,
        # tl3: 18,
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

    cacheSize  = options[:cacheSize]
    # workloads to run on p1-p3
    p0         = options[:p0]
    p1         = options[:p1]
    p2         = options[:p2]
    p3         = options[:p3]
    # turn length for p0-p3. Assumed equal unless diffperiod is supplied. The 
    # turn length is 2**arg unless diffperiod is supplied, otherwise it is arg.
    tl0        = options[:tl0]
    tl1        = options[:tl1]
    tl2        = options[:tl2]
    tl3        = options[:tl3]
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
      n = 0; until eval "options[:p#{n}].nil?"
        n += 1
      end; n
    )

    o = options

    filename = "#{scheme}_#{numcpus}cpus_#{p0}#{tl0}_#{p1}#{tl1}"
    filename = "#{scheme}_#{numcpus}cpus_#{o[:wl_name]}" unless o[:wl_name].nil?

    filename = "#{options[:nametag]}_"+filename if options[:nametag]
    filename = options[:filename] unless options[:filename].nil?
  
    FileUtils.mkdir_p( result_dir ) unless File.directory?( result_dir )

    script = File.new($scriptgen_dir.path+"/run_#{filename}","w+")
    script.puts("#!/bin/bash")
    script.puts("build/ARM/gem5.fast \\") unless debug
    script.puts("build/ARM/gem5.debug \\") if debug 
    script.puts("--debug-flags=Cache \\") if cacheDebug
    script.puts("--debug-flags=MMU \\") if mmuDebug
    script.puts("--debug-flags=Bus,MMU,Cache\\") if options[:memdebug]
    script.puts("    --stats-file=#{filename}_stats.txt \\")
    script.puts("    configs/#{options[:config] || "dramsim2/dramsim2_se.py"} \\")
    script.puts("    --numcpus=#{options[:numcpus]} \\")
    script.puts("    --cpu-type=#{cpu} \\")
    script.puts("    --caches \\")
    script.puts("    --l2cache \\") unless options[:nol2]
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

    numcpus.times do |n|
      script.puts "    --p#{n}=#{invoke(options[eval ":p#{n}"])} \\"
    end

    unless options[:nodramsim]
      script.puts("    --dramsim2 \\")
      #script.puts("    --tpturnlength=#{tl0} \\") unless tl0==0 || diffperiod
      script.puts("    --devicecfg="+
                  "./ext/DRAMSim2/ini/#{$device} \\")
      script.puts("    --systemcfg=./ext/DRAMSim2/system_#{scheme}.ini \\") unless tl0==0
      script.puts("    --systemcfg=./ext/DRAMSim2/system_ft.ini \\") if tl0==0
      script.puts("    --outputfile=/dev/null \\")


      script.puts("   --diffperiod \\")
      script.puts("   --p0period=#{tl0} \\")
      script.puts("   --p1period=#{tl1} \\")
    end

    script.puts("    > #{result_dir}/stdout_#{filename}.out")
    script_abspath = File.expand_path(script.path)
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

def iterate_and_submit opts={}, &block
    o = {
        cpus: %w[detailed],
        schemes: $schemes,
        benchmarks: $specint,
        runmode: :local,
        threads: 4
    }.merge opts

    o[:otherbench] = o[:benchmarks] if o[:otherbench].nil?

    f = []

    submit = block_given? ?
      block :
      ( lambda do |param, p0, other|
          r = sav_script(param.merge(p0: p0, p1: other))
          (r[0] && [] ) || r[1]
        end
      )
      
    o[:cpus].product(o[:schemes]).each do |cpu, scheme|
      o[:benchmarks].product(o[:otherbench]).each_slice(o[:threads]) do |i|
        threads=[]
        o.merge!(scheme: scheme, cpu: cpu)
        i.each do |p0,other|
          threads << Thread.new { f << submit.call(o, p0, other) }
        end
        threads.each { |t| t.join }
      end
    end
    puts f.flatten.to_s.red
end

def parallel_local opts={}
  iterate_and_submit opts
end

def qsub_fast opts={}
  iterate_and_submit ({runmode: :qsub, threads: 1}).merge(opts)
end

def single opts={}
    o = {
        cpu: "detailed",
        schemes: %w[ none],
        scheme: "none",
        benchmarks: $specint,
        threads: 1
    }.merge opts

    #f = []

    o[:benchmarks].each do |b|
        sav_script o.merge(p0: b)
    end

    # o[:schemes].product(o[:benchmarks]).each_slice(o[:threads]) do |i|
    #   t={}
    #   i.each do |scheme,p0|
    #     t[i] = Thread.new do
    #       r=sav_script(o.merge(p0: p0))
    #       f << r[1] unless r[0]
    #     end
    #   end
    #   t.each { |_,v| v.join }
    # end
    # puts f.flatten.to_s.red
end

def single_qsub opts={}
  single opts.merge(runmode: :qsub)
end

def parallel_local_scaling opts={}
  iterate_and_submit(opts) do |param, p0, other|
    f = []
    p = param.merge(p0: p0)
    #2
    p = p.merge(p1: other)
    p = p.merge coordinate(n:2) if opts[:coordination]
    r = opts[:skip2]? [true,""] : sav_script(p)
    f << r[1] unless r[0]
    #3
    p = p.merge(p2: other)
    p = p.merge coordinate(n:3) if opts[:coordination]
    r = opts[:skip3]? [true,""] : sav_script(p)
    f << r[1] unless r[0]
    #4
    p = p.merge(p3: other)
    p = p.merge coordinate(n:4) if opts[:coordination]
    r = opts[:skip4]? [true,""] : sav_script(p)
    f << r[1] unless r[0]
    f
  end
end

def scale_to opts={}
  opts = { num_wl: 2 }.merge opts
  iterate_and_submit(opts) do |param, p0, other|
    f = []
    p = param.merge(p0: p0)
    1.upto(opts[:num_wl]-1) do |n|
      p = p.merge( "p#{n}".to_sym => other ) 
      r = (eval "opts[:skip#{n+1}]") ? [true,""] : sav_script(p)
      f << r[1] unless r[0]
    end
    f
  end
end

def iterate_mp o={}
  o = {
    num_wl: 2,
    workloads: $mpworkloads,
    skip3: true,
    skip5: true,
    skip7: true
  }.merge o

  2.upto(o[:num_wl]) do |n|
    wls = workloads_of_size n, o[:workloads]
    wls = wls.merge(rotated_workloads wls)
    wls.keys.each do |wl|
      p = o.merge(wl_name: wl)
      wls[wl].each_with_index do |benchmark,i|
        p = p.merge( "p#{i}".to_sym => benchmark )
      end
      sav_script p unless eval("o[:skip#{n}]")
    end
  end

end

def qsub_scaling opts = {}
  parallel_local_scaling opts.merge(runmode: :qsub)
end

end
