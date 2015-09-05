Dir['*rb'].each { |f| require_relative f }
require 'colored'

def acceptance_probability e, e_prime, temp
  return 1.0 if e_prime <= e
  d = (e-e_prime)/e.to_f * 25
  r = Math.exp(-1*(d.abs) * (1.0-temp))
  puts "P=#{r}".to_s.yellow if DEBUG_S
  r
end

def temperature time
  0.95 ** time
end

def simulate_annealing o={}
  o = {
    init: lambda { State.shuffle },
    max_time: 400
  }.merge o

  time = 0 
  max_time = o[:max_time] 
  best_state = nil
  best_state = current_state = o[:init].call

  while time < max_time

    if DEBUG_S
      puts "=" * 80
      puts " "*38 + "#{time}" + " "*38
      puts "=" * 80
    end

    new_state = current_state.neighbor

    if DEBUG_S
      puts current_state.to_s.blue
      puts new_state.to_s.magenta
    end

    e, e_prime = current_state.energy, new_state.energy
    temp = temperature(time)

    if DEBUG_S
      puts "e = #{current_state.energy}".to_s.blue
      puts "e_prime = #{new_state.energy}".to_s.magenta
    end

    if rand < acceptance_probability( e, e_prime, temp )
      puts "ACCEPT".green if DEBUG_S
      current_state = new_state
    end

    if current_state.energy < best_state.energy
      best_state = current_state
    end

    # Dare to dream
    (puts "hi"; break) if best_state.energy == 0

    puts "best_energy= #{best_state.energy}".red if DEBUG_S
    puts best_state.to_s.red if DEBUG_S

    time += 1

  end

  puts "best energy #{best_state.energy}"
  puts "best_state #{best_state}"

end

if __FILE__ == $0
  DEBUG_S = true

  simulate_annealing(
    max_time: 300_000,
    init: lambda do
        State.new(
            a_0: 1,
            a_1: 1,
            b_0: 1/4.to_f,
            b_1: 1/4.to_f,
        )
    end,
  )

end
