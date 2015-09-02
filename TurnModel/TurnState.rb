class State
    def initialize o = {}
        @o = {
            #Helpful reminder of workload
            name: "nothing", 

            # input parameters
            access_time: 12,
            min_turn: 23,
            # target bandwidths
            b_0: 1,
            b_1: 1,

            # accesses per turn
            a_0: 1,
            a_1: 1
        }.merge o

        # variables that can be controlled
        @params = [ :a_0, :a_1 ] 

        # step variables
        @deltas = (-3..3).to_a
    end

    # randomly generate a state
    def self.shuffle o
        State.new o.merge(
            a_0: (5000.times.to_a).sample,
            a_1: (5000.times.to_a).sample
        )
    end

    # the equation to be minimized
    def energy
        tl_0 = @o[:access_time] * (@o[:a_0] - 1) + @o[:min_turn]
        tl_1 = @o[:access_time] * (@o[:a_1] - 1) + @o[:min_turn]
        s = tl_0 + tl_1
        e_0 = (@o[:a_0] / s.to_f - @o[:b_0]).abs
        e_1 = (@o[:a_1] / s.to_f - @o[:b_1]).abs
        e_0 ** 2 + e_1 ** 2
    end

    # randomly generate a neighboring state
    def neighbor
        State.new @o.merge(
            (var = @params.sample) => (@o[var] + @deltas.sample).abs
        )
    end

    def to_s() @o.to_s end

end
