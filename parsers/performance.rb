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
  # hld: %w[ mcf h264ref ],
  hmi: %w[ libquantum sjeng ],
  # hmd: %w[ xalan gcc ],
  # mmi: %w[ gcc gobmk ],
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
  # hld: %w[ mcf h264ref ],
  hmi: "lib_sjg",
  # hmd: %w[ xalan gcc ],
  # mmi: %w[ gcc gobmk ],
  mmd: "sjg_sjg",
  llp: "ast_h264",
  lld: "h264_hmr",
  lli: "ast_ast"
}

$workload_names = $mpworkloads.keys.map { |k| k.to_s }
$new_names = $mpworkload_nn.keys.map { |k| $mpworkload_nn[k] }

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

if __FILE__ == $0
  in_dir  = ARGV[0].to_s
  out_dir = ARGV[1].to_s
  FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

  o = { core_set: [2], dir: in_dir, numcpus: 2, scheme: "none",
        x_label: "System Throughput" }
 
  gb_graph = lambda do |r,name|
    gb = grouped_bar r.transpose, legend: [2,4,6,8], x_labels: $new_names
    string_to_f gb, "#{out_dir}/#{name}.svg"
  end

#------------------------------------------------------------------------------
# Experiments
#------------------------------------------------------------------------------
graphs = lambda do |fun,mname|  
  # baseline
  puts "Baseline #{fun}".green
  r = fun.call o.merge(
    core_set: [2,4,6,8]
  )
  puts r.to_s
  gb_graph.call r, "baseline_#{mname}"

  #n_core_ntc
  puts "N Core N TC #{fun}".green
  r = fun.call o.merge(
    scheme: "tp",
    core_set: [2,4,6,8],
  )
  puts r.to_s
  gb_graph.call r, "n_core_n_tc_#{mname}"
  
  # n_core_2tc
  puts "N Core 2 TC ".green
  r = fun.call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [4,6,8]
  )
  puts r.to_s
  gb = grouped_bar r.transpose, legend: [4,6,8], x_labels: $new_names
  string_to_f gb, "#{out_dir}/n_core_2_tc_#{mname}.svg"

  # breakdown
  puts "Breakdown #{fun}".green
  r = [
    (fun.call o.merge(
      scheme: "none",
      nametag: "only_waypart",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      scheme: "none",
      nametag: "only_rrbus",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      scheme: "tp",
      nametag: "only_mc",
      cores: 2
    )).flatten,
  ]
  puts r.to_s
  gb = grouped_bar(r.transpose, legend: %w[cache bus mem], x_labels: $new_names,
                    legend_space: 40)
  string_to_f gb, "#{out_dir}/breakdown_#{mname}.svg"

  # # Flushing overhead
  puts "Flushing #{fun}".green
  r = [
    (fun.call o.merge(
      nametag: "flush1ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      nametag: "flush10ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      nametag: "flush100ms",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]
  puts r.to_s
  # gb = grouped_bar(r.transpose, legend: %w[1ms 10ms 100ms], x_labels: $workload_names,
  #                  legend_space: 45)
  # string_to_f gb, "#{out_dir}/flushing_#{fun}.svg"
end

normgraphs = lambda do |fun, mname|

  o = { x_labels: $new_names, x_title: "Normalized STP",
         core_set: [2], dir: in_dir, numcpus: 2, scheme: "none" }

  # baseline
  baseline = fun.call o.merge(
    core_set: [2,4,6,8]
  )

  #n_core_ntc
  ntc = fun.call o.merge(
    scheme: "tp",
    core_set: [2,4,6,8],
  )

  # n_core_2tc
  twotc = fun.call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [4,6,8]
  )

  # breakdown
  breakdown = [
    (fun.call o.merge(
      nametag: "only_waypart",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      nametag: "only_rrbus",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      scheme: "tp",
      nametag: "only_mc",
      cores: 2
    )).flatten,
  ]

  # # Flushing overhead
  flushing = [
    (fun.call o.merge(
      nametag: "flush1ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      nametag: "flush10ms",
      scheme: "tp",
      cores: 2
    )).flatten,
    (fun.call o.merge(
      nametag: "flush100ms",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]

  #NTC normalized to base
  r = normalized( ntc, baseline )
  gb = grouped_bar r.transpose, o.merge( legend: %w[2 4 6 8] )
  string_to_f gb, "#{out_dir}/ntc_#{mname}_norm.svg"
    
  # #2TC normalized to NTC
  r = normalized( twotc, ntc[1..-1] )
  gb = grouped_bar r.transpose, o.merge( legend: %w[4 6 8] )
  string_to_f gb, "#{out_dir}/twotc_#{mname}_norm.svg"
    
  # #Breakdown normalized to base
  r = normalized( breakdown+[ntc[0]], [baseline[0]]*4 )
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[cache bus mem total],
    legend_space: 40
  )
  string_to_f gb, "#{out_dir}/breakdown_#{mname}_norm.svg"

  # # Flushing Overhead
  # r = normalized( [ntc[0]]+flushing, baseline[0]*4 )
  # gb = grouped_bar r.transpose, o.merge( legend: %w[none 1ms 10ms 100ms] )

end

#------------------------------------------------------------------------------
# STP
#------------------------------------------------------------------------------
graphs.call( method(:stp_data_of), "stp" )
normgraphs.call( method(:stp_data_of), "stp")

#------------------------------------------------------------------------------
# ANTT
#------------------------------------------------------------------------------
# graphs.call( :antt_data_of )

#------------------------------------------------------------------------------
# Special Cases
#------------------------------------------------------------------------------
def normalized_progress o={}
  tisp = single_time o
  timp = find_time o
  (tisp.nil? || timp.nil?) ? [] : tisp/timp
end

def two_tc_wprogs o={}
  o = { dir: "results", x_labels: $new_names,
        x_title: "Normalized STP" }
  wls = $new_names
  secure, insecure = %w[tp none].map do|s|
    wls.keys.map do |wl|
      [
       normalized_progress(bench: wls[wl][0], scheme: s),
       normalized_progress(bench: wls[wl][1], r: true , schem: s),
       stp(workload: wl, numcpus: 2, scheme: s)
      ]
    end
  end
  r.normalized( secure, insecure )
  gb = grouped_bar r.transpose o.merge( legend: %w[] )
  string_to_f gb, "foo/two_tc_wprogs.svg"
end

end
