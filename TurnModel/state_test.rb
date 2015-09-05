Dir['*rb'].each { |f| require_relative f }

if __FILE__ == $0
    s = State.new(
              a_0: 7, a_1: 7,
              b_0: 0.036 , b_1: 0.036
    ) 

    s.energy
    puts s
    puts s.energy
    
end
