#!/usr/bin/ruby
require 'colored'
require_relative 'parsers'
require_relative 'graph'
include Parsers


#------------------------------------------------------------------------------
# Absolute (Non-Normalized) Graphs
#------------------------------------------------------------------------------
def abs_baseline o={}
  r = o[:fun].call o.merge(
    core_set: [2,3,4]
  )
  gb = grouped_bar r.transpose, legend: [2,3,4], x_labels: $new_names
  string_to_f gb, "#{o[:out_dir]}/baseline_#{o[:mname]}.svg"
end

def abs_ntc o={}
  r = o[:fun].call o.merge(
    scheme: "tp",
    core_set: [2,3,4],
  )
  gb = grouped_bar r.transpose, legend: [2,3,4], x_labels: $new_names
  string_to_f gb, "#{o[:out_dir]}/baseline_#{o[:mname]}.svg"
end

def abs_2tc o={}
  r = o[:fun].call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [3,4]
  )
  gb = grouped_bar r.transpose, legend: [2,3,4], x_labels: $new_names
  string_to_f gb, "#{o[:out_dir]}/n_core_2_tc_#{o[:mname]}.svg"
end

def abs_breakdown o={}
  r = [
    (o[:fun].call o.merge(
      scheme: "none",
      nametag: "only_waypart",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "none",
      nametag: "only_rrbus",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "only_mc",
      cores: 2
    )).flatten,
  ]
  gb = grouped_bar( r.transpose, legend: %w[cache bus mem],
                    x_labels: $new_names, legend_space: 40 )
  string_to_f gb, "#{o[:out_dir]}/breakdown_#{o[:mname]}.svg"
end

def abs_blocking_wb o={}
  r = [
    (o[:fun].call o.merge(
      nametag: "flush10ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush50ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]
  gb = grouped_bar(r.transpose, legend: %w[1ms 10ms 100ms],
                  x_labels: $workload_names, legend_space: 45)
  string_to_f gb, "#{o[:out_dir]}/blockingwb_flush_#{o[:mnmame]}.svg"
end

def abs_reserved_wb o={}
  r = [
    (o[:fun].call o.merge(
      nametag: "flush10ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush50ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]
  gb = grouped_bar(r.transpose, legend: %w[10ms 50ms 100ms],
                  x_labels: $workload_names, legend_space: 45)
  string_to_f gb, "#{o[:out_dir]}/reservedwb_flush_#{o[:mnmame]}.svg"
end

#------------------------------------------------------------------------------
# Normalized Graphs
#------------------------------------------------------------------------------
def baseline o={}
  o[:fun].call o.merge(
    #core_set: [2,3,4]
    core_set: [2]
  )
end

def ntc o={}
  o[:fun].call o.merge(
    scheme: "tp",
    #core_set: [2,3,4],
    core_set: [2]
  )
end

def norm_ntc o={}
  r = normalized( ntc(o), baseline(o) )
  gb = grouped_bar r.transpose, o.merge( legend: %w[2 3 4] )
  string_to_f gb, "#{o[:out_dir]}/ntc_#{o[:mname]}_norm.svg"
end

# n_core_2tc
def norm_2tc o={}
  twotc = o[:fun].call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [3,4]
  )
  r = normalized( twotc, ntc(o)[1..-1] )
  gb = grouped_bar r.transpose, o.merge( legend: %w[3 4] )
  string_to_f gb, "#{o[:out_dir]}/twotc_#{o[:mname]}_norm.svg"
end

# breakdown
def norm_breakdown o={}
  breakdown = [
    (o[:fun].call o.merge(
      nametag: "only_waypart",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "only_rrbus",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "only_mc",
      cores: 2
    )).flatten,
  ]

  r = normalized( breakdown+[ntc(o)[0]], [baseline(o)[0]]*4 )
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[cache bus mem total],
    legend_space: 40
  )
  string_to_f gb, "#{o[:out_dir]}/breakdown_#{o[:mname]}_norm.svg"
end

def norm_flushing_bw o={}
  flushing = [
    (o[:fun].call o.merge(
      nametag: "flush10ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush50ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_bw",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]

  r = normalized( [ntc(o)[0]]+flushing, [baseline(o)[0]]*4 )
  gb = grouped_bar r.transpose, o.merge( legend: %w[none 10ms 50ms 100ms] )
  string_to_f gb, "#{o[:out_dir]}/flushing_bw_#{o[:mname]}_norm.svg"
end

def norm_flushing_rbw o={}
  flushing = [
    (o[:fun].call o.merge(
      nametag: "flush10ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush50ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]

  r = normalized( [ntc(o)[0]]+flushing, [baseline(o)[0]]*4 )
  gb = grouped_bar r.transpose, o.merge( legend: %w[none 10ms 50ms 100ms] )
  string_to_f gb, "#{o[:out_dir]}/flushing_rbw_#{o[:mname]}_norm.svg"
end

def norm_params o={}
  params = [
    (o[:fun].call o.merge(
      scheme: "tp",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l2miss_opt",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l2miss_max_old",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3hit_opt",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3hit_max",
      core_set: [2]
    )).flatten,
    # (o[:fun].call o.merge(
    #   scheme: "tp",
    #   nametag: "l3miss_opt",
    #   core_set: [2]
    # )).flatten,
    # (o[:fun].call o.merge(
    #   scheme: "tp",
    #   nametag: "l3miss_max",
    #   core_set: [2]
    # )).flatten,
  ]

  #r = normalized([ntc(o)[0]]+params, [baseline(o)[0]]*3)
  r = normalized(params, [baseline(o)[0]]*5)
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[
      default
      l2miss_opt l2miss_max
      l3hit_opt  l3hit_max
    ]
  )
  string_to_f gb, "#{o[:out_dir]}/params_#{o[:mname]}_norm.svg"
end

def norm_params_nocwf o={}
  params = [
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "nocwf",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l2miss_opt_nocwf",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l2miss_max_nocwf",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3hit_opt_nocwf",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3hit_max_nocwf",
      core_set: [2]
    )).flatten,
    # (o[:fun].call o.merge(
    #   scheme: "tp",
    #   nametag: "l3miss_opt",
    #   core_set: [2]
    # )).flatten,
    # (o[:fun].call o.merge(
    #   scheme: "tp",
    #   nametag: "l3miss_max",
    #   core_set: [2]
    # )).flatten,
  ]

  #r = normalized([ntc(o)[0]]+params, [baseline(o)[0]]*3)
  r = normalized(params, [baseline(o)[0]]*5)
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[
      default
      l2miss_opt l2miss_max
      l3hit_opt  l3hit_max
    ]
  )
  string_to_f gb, "#{o[:out_dir]}/params_nocwf_#{o[:mname]}_norm.svg"
end

if __FILE__ == $0
  in_dir  = ARGV[0].to_s
  out_dir = ARGV[1].to_s
  FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

  abs_o = {
    core_set: [2],
    dir: in_dir,
    out_dir: out_dir,
    numcpus: 2,
    scheme: "none",
    x_label: "System Throughput",
    fun: method(:stp_data_of),
    mname: "stp"
  }

  # abs_baseline abs_o
  # abs_ntc abs_o
  # abs_2tc abs_o
  # abs_breakdown abs_o
  # abs_blocking_wb abs_o
  # abs_reserved_wb abs_o
  
  normo = {
    x_labels: $new_names,
    x_title: "Normalized STP",
    core_set: [2],
    dir: in_dir,
    out_dir: out_dir,
    numcpus: 2,
    scheme: "none",
    fun: method(:stp_data_of),
    mname: "stp"
  }

  # norm_ntc normo
  # norm_2tc normo
  # norm_breakdown normo
  norm_flushing_bw  normo
  norm_flushing_rbw normo

  norm_params normo
  norm_params_nocwf normo

  # svg2pdf out_dir

end
