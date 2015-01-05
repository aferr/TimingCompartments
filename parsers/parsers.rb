#!/usr/bin/ruby

require 'csv'
require 'fileutils'
require 'colored'

module Parsers

$cpus = %w[timing detailed]
$specint = [
    'astar',
    'bzip2',
    'gcc',
    'gobmk',
    'h264ref',
    'hmmer',
    'libquantum',
    'mcf',
    #    'omnetpp',
    #    'perlbench',
    'sjeng',
    'xalan',
]
$schemes = %w[ none tp ]

# Workloads
def benchmarks_in wl
  {
    hhd: %w[ mcf bzip2 ],
    hhn: %w[ mcf xalan ],
    hhi: %w[ libquantum libquantum],
    hli: %w[ libquantum astar ],
    hld: %w[ mcf h264ref ],
    hmi: %w[ libquantum sjeng ],
    #hmd: %w[ xalan gcc ],
    mmi: %w[ gcc gobmk ],
    mmd: %w[ sjeng sjeng ],
    llp: %w[ astar h264ref ],
    lld: %w[ h264ref hmmer ],
    lli: %w[ astar astar]
  }[wl]
end

$mpworkloads = {
  hhd: %w[ mcf bzip2 ],
  hhn: %w[ mcf xalan ],
  hhi: %w[ libquantum libquantum],
  hli: %w[ libquantum astar ],
  hld: %w[ mcf h264ref ],
  hmi: %w[ libquantum sjeng ],
  #hmd: %w[ xalan gcc ],
  mmi: %w[ gcc gobmk ],
  mmd: %w[ sjeng sjeng ],
  llp: %w[ astar h264ref ],
  lld: %w[ h264ref hmmer ],
  lli: %w[ astar astar]
}

$mpworkload_nn = {
  hhd: "mcf_bz2",
  hhn: "mcf_xln",
  hhi: "lib_lib",
  hli: "lib_ast",
  hld: "mcf_h264ref",
  hmi: "lib_sjg",
  #hmd: "xalan_gcc",
  mmi: "gcc_gobmk",
  mmd: "sjg_sjg",
  llp: "ast_h264",
  lld: "h264_hmr",
  lli: "ast_ast"
}


$workload_names = $mpworkloads.keys.map { |k| k.to_s }
$new_names = $mpworkload_nn.keys.map { |k| $mpworkload_nn[k] }
#-------------------------------------------------------------------------------
# Filenames
#-------------------------------------------------------------------------------
def filename( p={} )
  p[:nametag] = p[:nametag]+"_" unless p[:nametag].nil?
  "#{p[:nametag]}#{p[:scheme]}_#{p[:numcpus]}cpus_#{p[:workload]}"
end

def stdo_file( p={} )
  p={dir: "results"}.merge p
  "#{p[:dir]}/stdout_#{filename p}.out"
end

def m5out_file( p={} )
    p = {dir: "m5out"}.merge p
    "m5out/#{filename p}_stats.txt"
end

def bench_swap_file( p={} )
    filename( p.merge{ p0:p[:p1], p1:[p:p0] } )
end

def single_stdo( p={} )
  p={dir: "results"}.merge p
  "#{p[:dir]}/stdout_none_1cpus_#{p[:bench]}64_#{64}.out"
end

# This can be memoized or eagerly constructed later.
def single_time( p={} )
  find_time single_stdo p
end

#-------------------------------------------------------------------------------
# Data parsing
#-------------------------------------------------------------------------------
MEMLATENCY = /system.l20.overall_miss_latency::total\s*(\d*.\d*)/

def get_m5out_stat(filename, opts={})
  puts filename.to_s.blue
  (puts filename.red; return 0) unless File.exists? filename
  time = nil
  File.open(filename,'r') do |f|
    f.each_line do |line|
      return line.match(MEMLATENCY)[1].to_f if line =~ MEMLATENCY
    end
  end
  puts filename.blue
  0
end


def find_time(filename, opts = {} )
  (puts filename.red; return nil) unless File.exists? filename
  time = nil
  File.open(filename,'r') do |f|
    #timingregex = /Exiting @ tick (\d*)\w* because a\w*/
    timingregex = /Exiting @ tick (\d*)\w* because a\w*/
    f.each_line do |line|
      return line.match(timingregex)[1].to_f if line =~ timingregex
    end
  end
  puts filename.blue
  time
end

def get_datum( filename, regex )
    unless File.exists? filename
        return [nil, false] 
    end
    File.open(filename, 'r'){|f|
        f.each_line do |line|
            return [line.match(regex)[1],true] if line =~ regex
        end
    }
    [nil, false]
end

#-------------------------------------------------------------------------------
# Data computation
#-------------------------------------------------------------------------------
# System Throughput
def stp( p={} )
  wl = p[:workload]
  s = p[:numcpus].times.map do |i|
    tisp = single_time p.merge(bench: benchmarks_in(wl)[i%2], )
    timp = find_time stdo_file(i%2 == 1 ? p.merge(workload: wl.to_s + 'r') : p)
    (tisp.nil? || timp.nil?) ? [] : tisp/timp
  end
  s.include?([]) ? 0 : s.reduce(:+)
end

# Average Normalized Turnaround Time
def antt( p={} )
  wl = p[:workload]
  s = p[:numcpus].times.map do |i|
    tisp = single_time p.merge(bench: benchmarks_in(wl)[i%2])
    timp = find_time stdo_file(i%2 == 1 ? p.merge(workload: wl.to_s + 'r') : p)
    (tisp.nil? || timp.nil?) ? [] : timp/tisp
  end
  s.include?([]) ? 0 : s.reduce(:+)
end

def data_of p={}
  p[:core_set].inject([]) do |a1,cores|
    a1 << $mpworkloads.keys.inject([]) do |a2,wl|
      a2 << yield(p.merge(numcpus: cores, workload: wl))
      a2
    end
    a1
  end
end

def stp_data_of(p={}) data_of(p){|o| stp o} end

def antt_data_of(p={}) data_of(p){|o| antt o} end

def latency_data_of(p={}) data_of(p){|o| get_m5out_stat(m5out_file o)} end

def normalized d1, d2
  d1.each_with_index.map do |x,i|
    x.each_with_index.map do |y,j|
      d2[i][j] == 0 ? 0 : y / d2[i][j]
    end
  end
end

def percent_overhead d1, d2
  d1.each_with_index.map do |x,i|
    x.each_with_index.map do |y,j|
      d2[i][j] == 0 ? 0 : (( d2[i][j] - y ) / d2[i][j])
    end
  end
end

#-------------------------------------------------------------------------------
# Utility
#-------------------------------------------------------------------------------
def avg_arr arr
    (arr.length != 0 && arr.inject(:+)/arr.length) || -1 #0xf00
end

def string_to_f string, filename
    File.open(filename, 'w') { |f| f.puts string }
end

def hash_to_csv( hash, filename, p={} )
    CSV.open( filename, 'w' ) do |csv_object|
        hash.to_a.each{|row| csv_object << row}
    end
end

def svg2pdf dir
  tmpdir = Dir.pwd
  Dir.chdir dir
  # This is a bash script that converts all the svgs in the current working
  # directory into pdfs
  %x[svg2pdfall]
  Dir.chdir tmpdir
end

#this is the module end
end

if __FILE__ == $0
  include Parsers
  p = { numcpus: 2, scheme: "tp", dir: "results", workload: :mmi}
  puts stp p
end
