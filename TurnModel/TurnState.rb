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
        @o[:tl_0] = @o[:access_time] * (@o[:a_0] - 1) + @o[:min_turn]
        @o[:tl_1] = @o[:access_time] * (@o[:a_1] - 1) + @o[:min_turn]
        @o[:s] = @o[:tl_0] + @o[:tl_1]
        @o[:e_0] = @o[:b_0] - @o[:a_0] / @o[:s].to_f
        @o[:e_1] = @o[:b_1] - @o[:a_1] / @o[:s].to_f
        @o[:e_0]**2 + @o[:e_1]**2
    end

    # randomly generate a neighboring state
    def neighbor
        var = @params.sample
        val = @o[var] + @deltas.sample
        val = val <= 0 ?  1 : val
        State.new @o.merge(var => val)
    end

    def to_s() @o.to_s end

end
