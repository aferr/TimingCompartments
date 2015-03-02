#!/bin/ruby
require_relative 'get_running.rb'

# lastlines txt is found by running tail -n 1 * > lastlines.txt in the 
# directory with the results
exitregex = /Exiting @ tick (\d*)\w* because a thread in cpu0/
fnamereg = /==> stdout_(\w*)\.out <==/
running = get_running
File.readlines("lastlines.txt").each_slice(3){|l1,l2,l3|
    fn = l1.match(fnamereg)[1]
    unless l2 =~ exitregex || running.include?(fn)
        puts fn
    end
}
