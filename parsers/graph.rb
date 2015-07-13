require 'rubyvis'
require_relative 'parsers'
include Parsers

module Parsers

PAPER_DIM = {
    h: 190,
    w: 300,
    left: 30,

    font: "9px sans-serif",
        
    lower_text_margin: 24,
    group_space: 7,
    dot_size: 15,
    legend_margin: 10,
}

TWO_COLUMN = PAPER_DIM.merge(
    w: 600
)

MINI_DIM = PAPER_DIM.merge(
    w: 140
)

def grouped_csv data, o={}
  o = {
    x_labels: $specint,
    legend: %w[],
    do_avg: true,
    rotate_x_labels: true
  }.merge o

  str = "%-15s" % "bench," +  "#{o[:legend].inject("") { |s, l| s += "%-15s" % "#{l}, " }} \n" +
    data.each_with_index.inject("") do |s, (bench_data, i)|
        s += "%-15s" % "#{o[:workloads].keys.map{ |wl| wl.to_s}[i]}, " +
          bench_data.inject("") do |si, legend_data|
              si += "%-13f" % legend_data + ", "; si
          end + "\n"
        s
    end

  # Add Averages
  str += "%-15s" % "avg,"
  str += data.transpose.map do |bench_data|
      bench_data.reject { |element| element == 0 }
  end.map do |bench_data|
      bench_data == [] ? 0 : bench_data.reduce(:+) / bench_data.size
  end.inject("") do |s, avg_data|
      s += "%-13f" % avg_data + ", "; s
  end + "\n"

  str

end

def csv_to_arr filename, o={}
    o = {keep_list: o[:x_labels]}.merge o
    (CSV.read filename)[1..-1].reject do |name,_,_|
        not (o[:keep_list].include? name)
    end.transpose[1..-2].map do |i|
        i.map { |j| j.to_f }
    end
end

def grouped_bar data, o={}
    o = {
        w: 700, 
        h: 300,
        left: 65,
        right: 40,
        
        value_format: "%.2f",
        font: "16px sans-serif",

        y_label: "Overhead",
        num_ticks: 8,
        
        lower_text_margin: 30,
        group_space: 20,
        dot_size: 20,
        legend_margin: 18,

    }.merge o

    h = o[:h]
    w = o[:w] -25


    vis = pv.Panel.new.
        width(w).
        height(h).
        left(o[:left]).
        right(o[:right])

    colors = pv.Colors.category20()
    data_max = data.flatten.max
    bar_width = o[:bar_width] ||
        ( w - data[0].size * o[:group_space] ) / data.flatten.size.to_f
    group_width = data.size * bar_width + o[:group_space]
    bar_scale = (o[:h] - o[:legend_margin] - o[:dot_size] -
                 o[:lower_text_margin]*2 )/ (o[:max_scale] || data_max).to_f
    
    # Y-Axis Scale 
    y = pv.Scale.linear(0, o[:max_scale] || data_max).
        range(o[:lower_text_margin]*2, o[:h] - o[:legend_margin] -
             o[:dot_size])


    #Outer Labels
    if o[:rotate_x_labels]
    vis.add(pv.Label).
        data(data[0]).
        bottom(0).#o[:lower_text_margin]).
        text(lambda { o[:x_labels][index] } ).
        font(o[:font]).
        text_angle(-Math::PI/2).
        left(lambda { o[:left] + group_width * (index + 0.5) +
                     (group_width - o[:group_space] - bar_width)/2.0 } )
    else
    vis.add(pv.Label).
        data(data[0]).
        bottom(0).#o[:lower_text_margin]).
        text(lambda { o[:x_labels][index] } ).
        font(o[:font]).
        left(lambda { o[:left] + group_width * index +
                     (group_width - o[:group_space] - bar_width)/2.0 } )
    end


    #White bars across width
    vis.add(pv.Rule).
        data(y.ticks(o[:num_ticks])).
        bottom(lambda { |d| y.scale(d)}).
        stroke_style(lambda { |d|  "rgba(140,140,140,.3)" } ).
        lineWidth(2).
        left(8).
        width(w+20)

    data.size.times do |group|
        bar = vis.add(pv.Bar).
            data(data[group]).
            width(bar_width).
            height(lambda { |d| d * bar_scale } ).
            left(lambda { o[:left] + group*bar_width + index * group_width} ).
            bottom(o[:lower_text_margin] * 2).
            fillStyle(lambda {colors.scale(group) } ).
            lineWidth(1).
            strokeStyle("#000")

        if o[:numeric_labels]
          bar.anchor("top").add(pv.Label).
              text_style("white").
              font(o[:font]).
              text(lambda { |d| o[:value_format] % d } )
        end
    end


    unless o[:legend].nil?
        legend_space = group_width * data[0].size / o[:legend].size.to_f
        vis.add(pv.Dot).
            data(o[:legend]).
            top(o[:legend_margin]).
            shape_size(o[:dot_size]).
            fillStyle(lambda { colors.scale(index) }).
            line_width(0).
            left(lambda { o[:left] + o[:dot_size]/2.0 + legend_space * index } ).
            anchor("right").
        add(pv.Label).
            text(lambda { |d| d.to_s }).
            font(o[:font])
    end
    
    #Horizontal line at bottom
    vis.add(pv.Rule).
        bottom(o[:lower_text_margin]*2).
        width(w+20).
        left(8)


    #Small bars and numbers on left
    vis.add(pv.Rule).
        data(y.ticks(o[:num_ticks])).
        bottom(lambda { |d| y.scale(d)}).
        left(8).
        width(4).
        lineWidth(2).
        stroke_style("#000").
        anchor("left").add(pv.Label).
        text(y.tick_format).
        font(o[:font])

    # Y-Axis Title
    unless o[:y_label].nil?
        vis.anchor("left").add(pv.Label).
            text(o[:y_label]).
            left(-25).
            text_align("center").
            font(o[:font]).
            text_angle(-Math::PI/2)
    end

    vis.render
    vis.to_svg

end

end

if __FILE__ == $0
    string_to_f (grouped_stacked_bar nil), "foo.svg"
end
