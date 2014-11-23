#!/usr/bin/ruby
require 'colored'
require_relative 'parsers'
require_relative 'graph'
include Parsers

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

if __FILE__ == $0
  in_dir  = ARGV[0].to_s
  out_dir = ARGV[1].to_s
  FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

  o = { core_set: [2], dir: in_dir, numcpus: 2, scheme: "none" }
 
  gb_graph_fake = lambda do |r,name|
    d = 1.upto(4).map{ |i| r[0].map{|j|j*i} }
    gb = grouped_bar d.transpose, legend: [2,4,6,8], x_labels: $mpworkloads.keys
    string_to_f gb, "#{out_dir}/#{name}.svg"
  end

#------------------------------------------------------------------------------
# Experiments
#------------------------------------------------------------------------------
graphs = lambda do |fun|  
  # baseline
  puts "Baseline #{fun}".green
  r = (method fun).call o.merge(
    o
  )
  puts r.to_s
  gb_graph_fake.call r, "baseline_#{fun}"

  #n_core_ntc
  puts "N Core N TC #{fun}".green
  r = (method fun).call o.merge(
    scheme: "tp"
  )
  puts r.to_s
  gb_graph_fake.call r, "n_core_n_tc_#{fun}"
  
  # n_core_2tc
  puts "N Core 2 TC ".green
  r = (method fun).call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [4,6,8]
  )
  puts r.to_s
  gb = grouped_bar r.transpose, legend: [4,6,8], x_labels: $mpworkloads.keys
  string_to_f gb, "#{out_dir}/n_core_2_tc_#{fun}.svg"

  # breakdown
  puts "Breakdown #{fun}".green
  [
    ((method fun).call o.merge(
      scheme: "none",
      nametag: "only_waypart",
      cores: 2
    )).flatten,
    ((method fun).call o.merge(
      scheme: "none",
      nametag: "only_rrbus",
      cores: 2
    )).flatten,
    ((method fun).call o.merge(
      scheme: "none",
      nametag: "only_tp",
      cores: 2
    )).flatten,
  ]
  puts r.to_s
  gb = grouped_bar(r.transpose, legend: %w[cache bus mem], x_labels: $mpworkloads.keys,
                    legend_space: 40)
  string_to_f gb, "#{out_dir}/breakdown_#{fun}.svg"

  # Flushing overhead
  puts "Flushing #{fun}".green
  [
    ((method fun).call o.merge(
      nametag: "flush1ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    ((method fun).call o.merge(
      nametag: "flush10ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    ((method fun).call o.merge(
      nametag: "flush100ms",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]
  puts r.to_s
  gb = grouped_bar(r.transpose, legend: %w[1ms 10ms 100ms], x_labels: $mpworkloads.keys,
                   legend_space: 40)
  string_to_f gb, "#{out_dir}/flushing_#{fun}.svg"
end

#------------------------------------------------------------------------------
# STP
#------------------------------------------------------------------------------
graphs.call( :stp_data_of )

#------------------------------------------------------------------------------
# ANTT
#------------------------------------------------------------------------------
graphs.call( :antt_data_of )

end
