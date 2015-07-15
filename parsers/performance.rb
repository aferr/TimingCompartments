#!/usr/bin/ruby
require 'colored'
require_relative 'parsers'
require_relative 'graph'
include Parsers

def stp_2cores o={}
    puts "stp_2cores".green
    o = o.merge(core_set: [2], num_cpus: 2, workloads: $workloads_2core)
    leg = %w[Insecure Secure]
    if o[:parse]
        r = [
            (o[:fun].call o).flatten,
            (o[:fun].call o.merge(scheme: "tp")).flatten
        ]
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/stp_2cores.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/stp_2cores.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/stp_2cores.svg"
end

def stp_2cores_fakepart o={}
    puts "stp_2cores_fakepart".green
    o = o.merge(
        core_set: [2], num_cpus: 2, workloads: $workloads_2core,
        scheme: "tp"
    )
    leg = ["No Bank Partitioning", "Bank Partitioning"]
    if o[:parse]
        secure = [
            (o[:fun].call o).flatten,
            (o[:fun].call o.merge(nametag: "fake_part")).flatten
        ]
        baseline = [(o[:fun].call o.merge(scheme: "none")).flatten]*2
        r = normalized secure, baseline
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/stp_2cores_fakepart.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/stp_2cores_fakepart.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/stp_2cores_fakepart.svg"
end

def stp_4cores_fakepart o={}
    puts "stp_4cores_fakepart".green
    o = o.merge(
        core_set: [4], num_cpus: 4, workloads: $workloads_4core,
        scheme: "tp"
    )
    leg = ["No Bank Partitioning", "Bank Partitioning"]
    if o[:parse]
        secure = [
            (o[:fun].call o).flatten,
            (o[:fun].call o.merge(nametag: "fake_part")).flatten
        ]
        baseline = [(o[:fun].call o.merge(scheme: "none")).flatten]*2
        r = normalized secure, baseline
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/stp_4cores_fakepart.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/stp_4cores_fakepart.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/stp_4cores_fakepart.svg"
end

def ncores_ntcs o={}
    puts "ncores_ntcs".green
    leg = [2,4,6,8].map { |c| "#{c} Cores" }
    if o[:parse]
        tp = [2, 4, 6, 8].map do |cores|
            puts (eval "$workloads_#{cores}core")
            (o[:fun].call o.merge(
                scheme: "tp",
                core_set: [cores], num_cpus: cores,
                workloads: (eval "$workloads_#{cores}core")
            )).flatten
        end
        baseline = [2, 4, 6, 8].map do |cores|
            (o[:fun].call o.merge(
                core_set: [cores], num_cpus: cores,
                workloads: (eval "$workloads_#{cores}core")
            )).flatten
        end
        r = normalized tp, baseline
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/ncores_ntcs.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/ncores_ntcs.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/ncores_ntcs.svg"
end

def breakdown o={}
    puts "breakdown".green
    o = {
            filename: "breakdown", core_set: [8], 
            num_cpus: 8, workloads: $workloads_8core
        }.merge o
    leg = ["Cache", "Bus", "Memory Controller"]
    if o[:parse]
        r = normalized(
            (%w[only_waypart only_rrbus only_mc].map do |nt|
                (o[:fun].call o.merge(
                    scheme: (nt == "only_mc" ? "tp" : "none"),
                    nametag: nt
                )).flatten
            end),
            ( [(o[:fun].call o).flatten] * 3 )
        )
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/#{o[:filename]}.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/#{o[:filename]}.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/#{o[:filename]}.svg"
end

def more_cores_2tcs o={}
    puts "4cores 2tcs".green
    leg = %w[4TCs 2TCs insecure]
    o = o.merge(core_set: [4], num_cpus: 4, workloads: $workloads_4core)
    if o[:parse]
        r = [{scheme:  "tp"}, {scheme: "tp", nametag: "2tc"}, {}].map do |conf|
            (o[:fun].call o.merge conf).flatten
        end
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/4cores_2tcs.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/4cores_2tcs.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/4cores_2tcs.svg"
end

def cores8_2tcs o={}
    puts "8cores 2tcs".green
    leg = %w[8TCs 2TCs insecure]
    o = o.merge(core_set: [8], num_cpus: 8, workloads: $workloads_8core)
    if o[:parse]
        r = [{scheme:  "tp"}, {scheme: "tp", nametag: "2tc"}, {}].map do |conf|
            (o[:fun].call o.merge conf).flatten
        end
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/8cores_2tcs.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/8cores_2tcs.csv", o
    gb = grouped_bar r, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/8cores_2tcs.svg"
end

def flushing_vs_not o={}
    puts "flushing_vs_not".green
    leg = ["flushing", "no flushing"]
    o = o.merge(core_set: [2], num_cpus: 2)
    if o[:parse]
        secure = ["flush100ms_bw", nil].map do |nt|
            (o[:fun].call o.merge(
                scheme: "tp", nametag: nt
            )).flatten
        end
        insecure = [(o[:fun].call o).flatten] * 2
        r = normalized secure, insecure
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/flushing_vs_not.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/flushing_vs_not.csv", o.merge(legend: leg)
    puts r
end

def flushing_bw o={}
    puts "flushing".green
    leg = %w[10ms 50ms 100ms]
    o = o.merge(core_set: [2], num_cpus: 2)
    if o[:parse]
        secure = [10, 50, 100].map do |interval|
            (o[:fun].call o.merge(
                scheme: "tp", nametag: "flush#{interval}ms_bw"
            )).flatten
        end
        insecure = [(o[:fun].call o).flatten] * 3
        r = normalized secure, insecure
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/flushing_bw.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/flushing_bw.csv", o.merge(legend: leg)
    puts r
end

def flushing_rbw o={}
    puts "flushing".green
    leg = %w[10ms 50ms 100ms]
    o = o.merge(core_set: [2], num_cpus: 2)
    if o[:parse]
        secure = [10, 50, 100].map do |interval|
            (o[:fun].call o.merge(
                scheme: "tp", nametag: "flush#{interval}ms_rbw"
            )).flatten
        end
        insecure = [(o[:fun].call o).flatten] * 3
        r = normalized secure, insecure
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/flushing_rbw.csv"
    end
    r = csv_to_arr "#{o[:out_dir]}/flushing_rbw.csv", o.merge(legend: leg)
    puts r
end

def flushing_1core_bw o={}
    puts "flushing_1core_bw".to_s.green
    leg = %w[10ms 50ms 100ms]
    if o[:parse]
        secure = [10,50,100].map do |inter|
            $specint.map do |bench|
                ipc_reg = /system.switch_cpus.ipc\s*(\d*\.\d*)/
                f = "tc2_flush#{inter}ms_bw_tp_1cpus_#{bench}__stats.txt"
                f = "#{o[:dir]}/" + f
               find_stat f, ipc_reg, o
            end
        end
        baseline = [$specint.map do |bench|
            ipc_reg = /system.switch_cpus.ipc\s*(\d*\.\d*)/
            f = single_m5out o.merge(bench: bench)
            find_stat f, ipc_reg, o
        end] * 3
        r = normalized secure, baseline
        csv = grouped_csv r.transpose, o.merge(legend: leg)
        string_to_f csv, "#{o[:out_dir]}/flushing_1core_bw.csv"
    end
end

def cache_coherence o={}
    o = o.merge(x_labels: %w[fmm ocean_cp ocean_ncp radiosity water_nsq water_sp])
    leg = %w[insecure secure]
    data = [
        [0.9998, 0.9992],
        [0.9997, 1.0135],
        [0.9998, 0.9985],
        [0.9992, 0.9992],
        [0.9994, 0.9992],
        [0.9993, 0.9992],
    ].transpose
    puts data.to_s.green
    gb = grouped_bar data, o.merge(legend: leg)
    string_to_f gb, "#{o[:out_dir]}/#{o[:filename]}.svg"
end

#------------------------------------------------------------------------------
# "Main"
#------------------------------------------------------------------------------

if __FILE__ == $0
  in_dir  = ARGV[0].to_s
  out_dir = ARGV[1].to_s
  FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

  parse_o = {
      parse: true,
      core_set: [8],
      dir: in_dir,
      out_dir: out_dir,
      numcpus: 8,
      scheme: "none",
      fun: method(:stp_data_of),
      mname: "stp",
      workloads: $workloads_8core,
      keep_list: keep_list = %w[
        mcf_mcf
        mcf_lib
        lib_lib
        lib_ast
        lib_sjg
        sjg_sgj
        ast_h264
        h264_hmm
        ast_ast
        bz2_h264
        lib_gob
        sjg_h264
      ],
      #keep_list: keep_list = ($workloads_8core.keys.map { |i| i.to_s }),
      #x_labels: keep_list
      x_labels: %w[
        mcf_mcf
        mcf_lib
        lib_lib
        lib_ast
        lib_sjg
        sjg_sjg
        ast_h26
        h26_hm
        ast_ast
        bz2_h26
        lib_gob
        sjg_h26
      ],
  }

  normo = parse_o.merge( 
      # graph options
      y_label: "Normalized STP",
      rotate_x_labels: true,
      max_scale: 1.0
  ).merge(PAPER_DIM)

  abs_o = parse_o.merge(
      #graph options
      y_label: "System Throughput",
      rotate_x_labels: true
  ).merge(PAPER_DIM)

  cache_coherence parse_o.merge(
      y_label: "Normalized Execution Time",
      rotate_x_labels: true,
      min_scale: 0.990
  ).merge(PAPER_DIM)

  # stp_2cores abs_o
  # ncores_ntcs normo
  # breakdown normo
  # breakdown normo.merge(
  #     num_cpus: 2, core_set: [2], filename: "breakdown_2core"
  # )
  # breakdown normo.merge(
  #     num_cpus: 4, core_set: [4], filename: "breakdown_4core",
  # )
  # 
  # stp_2cores_fakepart normo
  # stp_4cores_fakepart normo
    
  # flushing_1core_bw normo.merge(parse: true)
  more_cores_2tcs abs_o
  cores8_2tcs abs_o
   
  # flushing_vs_not normo 
  # flushing_bw normo
  # flushing_rbw normo

  #svg2pdf out_dir

end
