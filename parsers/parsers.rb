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
    hmd: %w[ xalan gcc ],
    mmi: %w[ gcc gobmk ],
    mmd: %w[ sjeng sjeng ],
    llp: %w[ astar h264ref ],
    lld: %w[ h264ref hmmer ],
    lli: %w[ astar astar]
  }[wl]
end

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
    "#{p[:dir]}/#{filename p}_stats.txt"
end

def bench_swap_file( p={} )
    filename( p.merge{ p0:p[:p1], p1:[p:p0] } )
end

def single_stdo( p={} )
  p={dir: "results"}.merge p
  "#{p[:dir]}/stdout_none_1cpus_#{p[:bench]}43_#{43}.out"
end

# This can be memoized or eagerly constructed later.
def single_time( p={} )
  find_time single_stdo p
end

#-------------------------------------------------------------------------------
# Data parsing
#-------------------------------------------------------------------------------
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

def overhead( t1, t2 , p={} )
    unless t1.nil? || t2.nil?
        ( p[:X] && t1/t2 ) || (t1-t2)/t2 * 100
    end
end

def percent_diff(t1,t2)
     unless t1.nil? || t2.nil?
         high = ( t1>=t2 && t1 ) || ( true && t2 )
         low  = ( t1>=t2 && t2 ) || ( true && t1 )
         (high-low)/((high+low)/2) * 100
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

end

if __FILE__ == $0
  include Parsers
  p = { numcpus: 2, scheme: "tp", dir: "results", workload: :mmi}
  puts stp p
end
