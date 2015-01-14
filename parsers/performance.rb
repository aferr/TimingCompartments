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
    core_set: [2,4,6,8]
  )
  gb = grouped_bar r.transpose, o.merge(legend: [2,4,6,8])
  string_to_f gb, "#{o[:out_dir]}/baseline_#{o[:mname]}.svg"
end

def abs_ntc o={}
  r = o[:fun].call o.merge(
    scheme: "tp",
    core_set: [2,4,6,8],
  )
  gb = grouped_bar r.transpose, o.merge(legend: [2,4,6,8])
  string_to_f gb, "#{o[:out_dir]}/ntc_#{o[:mname]}.svg"
end

def abs_2tc o={}
  r = o[:fun].call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [3,4]
  )
  gb = grouped_bar r.transpose, o.merge(legend: [2,3,4])
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
  gb = grouped_bar r.transpose, o.merge(legend: %w[cache bus mem], legend_space: 40)
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
  gb = grouped_bar r.transpose, o.merge(legend: %w[1ms 10ms 100ms], legend_space: 45)
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
  gb = grouped_bar r.transpose, o.merge(legend: %w[10ms 50ms 100ms], legend_space: 45)
  string_to_f gb, "#{o[:out_dir]}/reservedwb_flush_#{o[:mnmame]}.svg"
end

#------------------------------------------------------------------------------
# Normalized Graphs
#------------------------------------------------------------------------------
def baseline o={}
  o[:fun].call o.merge(
    core_set: [2, 4, 6, 8]
  )
end

def ntc o={}
  o[:fun].call o.merge(
    scheme: "tp",
    core_set: [2, 4, 6, 8],
  )
end

def norm_ntc o={}
  r = normalized( ntc(o), baseline(o) )
  gb = grouped_bar r.transpose, o.merge( legend: %w[2 4 6 8] )
  string_to_f gb, "#{o[:out_dir]}/ntc_#{o[:mname]}_norm.svg"
end

# n_core_2tc
def norm_2tc o={}
  twotc = o[:fun].call o.merge(
    scheme: "tp",
    nametag: "2tc",
    core_set: [4] #[4, 6, 8]
  )
  base = ntc( o.merge( coreset: [4] ) ) #core_set: [4, 6, 8] ) )
  r = normalized( twotc, base )
  gb = grouped_bar r.transpose, o #, o.merge( legend: %w[4 6 8] )
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
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[none 10ms 50ms 100ms],
    legend_space: 40
  )
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
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[none 10ms 50ms 100ms],
    legend_space: 40
  )
  string_to_f gb, "#{o[:out_dir]}/flushing_rbw_#{o[:mname]}_norm.svg"
end

def norm_flushing_partial o={}
  flushing = [
    (o[:fun].call o.merge(
      nametag: "flush100ms_rbw",
      scheme: "tp",
      cores: 2
    )).flatten,
  ]

  partial = [
    (o[:fun].call o.merge(
      nametag: "flush100ms_iw025",
      scheme: "none",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_iw05",
      scheme: "none",
      cores: 2
    )).flatten,
    (o[:fun].call o.merge(
      nametag: "flush100ms_iw075",
      scheme: "none",
      cores: 2
    )).flatten,
  ]

  r = normalized( flushing*4, [baseline(o)[0]]+partial*3 )
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[none 25% 50% 75%],
    legend_space: 40
  )
  string_to_f gb, "#{o[:out_dir]}/flushing_partial#{o[:mname]}_norm.svg"
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
      nametag: "l2miss_max",
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
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3miss_opt",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3miss_max",
      core_set: [2]
    )).flatten,
  ]

  #r = normalized([ntc(o)[0]]+params, [baseline(o)[0]]*3)
  r = normalized(params, [baseline(o)[0]]*7)
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[
      default
      l2m_b l2m_w
      l3h_b l3h_w
      l3m_b l3m_w
    ],
    legend_space: 40
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
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3miss_opt",
      core_set: [2]
    )).flatten,
    (o[:fun].call o.merge(
      scheme: "tp",
      nametag: "l3miss_max",
      core_set: [2]
    )).flatten,
  ]

  #r = normalized([ntc(o)[0]]+params, [baseline(o)[0]]*3)
  r = normalized(params, [baseline(o)[0]]*7)
  gb = grouped_bar r.transpose, o.merge(
    legend: %w[
      default
      l2m_b l2m_w
      l3h_b l3h_w
      l3m_b l3m_w
    ],
    legend_space: 45
  )
  string_to_f gb, "#{o[:out_dir]}/params_nocwf_#{o[:mname]}_norm.svg"
end

if __FILE__ == $0
  in_dir  = ARGV[0].to_s
  out_dir = ARGV[1].to_s
  FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

  abs_o = {
    x_labels: $new_names,
    x_title: "System Throughput",
    core_set: [2],
    dir: in_dir,
    out_dir: out_dir,
    numcpus: 2,
    scheme: "none",
    fun: method(:stp_data_of),
    mname: "stp",
    h: 360,
    w: 864,
    font: "18px arial"
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
    mname: "stp",
    h: 340,
    w: 864,
    font: "18px arial"
  }

  # norm_ntc normo
  # norm_2tc normo
  #norm_breakdown normo
  
  norm_flushing_bw  normo
  norm_flushing_rbw normo
  norm_flushing_partial normo

  # paramo = normo.merge(bar_width: 1)
  # norm_params paramo
  # norm_params_nocwf paramo

  # svg2pdf out_dir

end
