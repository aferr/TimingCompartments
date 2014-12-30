#!/bin/ruby
require 'colored'

traceregex = /\w* system\.cpu0 T0(.*)$/

if __FILE__ == $0
  f1 = File.open(ARGV[0])
  f2 = File.open(ARGV[1])
  f1enum = Enumerator.new do |y|
    f1p = f1.each_line.lazy
    loop do
      n = f1p.next until n =~ traceregex
      y << n
    end
  end.lazy
  f2enum = Enumerator.new do |y|
    f2p = f2.each_line.lazy
    loop do
      n = f2p.next until n =~ traceregex
      y << n
    end
  end.lazy

  loop do
    break if lambda do |x, y|
      ins = ->(z){ z.match(traceregex)[1] }
      (puts "#{x}!=#{y}"; true) if ins.call(x) != ins.call(y)
    end.call(f1enum.next, f2enum.next)
  end

  f1.close
  f2.close

end
