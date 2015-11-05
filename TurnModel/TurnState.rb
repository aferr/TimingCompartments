class State
    def initialize o = {}
        @o = {
            #Helpful reminder of workload
            name: "nothing", 

            # input parameters
            k: 6,
            d: 23,
            f: 1,

            # enqueue rate in accesses per cycle
            b_0: 1,
            b_1: 1,

            # cpi in memory cycles per instruction
            base_cpi_0: 1,
            base_cpi_1: 1,

            # accesses per turn
            a_0: 1,
            a_1: 1
        }.merge o

        # variables that can be controlled
        @params = [ :a_0, :a_1 ] 

        # step variables
        @deltas = (-3..3).to_a

        # calc energy now so printing is accurate
        energy
    end


    # the equation to be maximized
    def energy_old
        @o[:tl_0] = @o[:k] * (@o[:a_0] - 1) + @o[:min_turn]
        @o[:tl_1] = @o[:k] * (@o[:a_1] - 1) + @o[:min_turn]
        @o[:s] = @o[:tl_0] + @o[:tl_1]

        @o[:cpi_lat_0] = @o[:base_cpi_0] +
            @o[:base_cpi_0] * @o[:b_0] * 0.5 *
            (@o[:s] - @o[:tl_0] + @o[:min_turn])**2 / @o[:s]
        @o[:cpi_lat_1] = @o[:base_cpi_1] +
            @o[:base_cpi_1] * @o[:b_1] * 0.5 *
            (@o[:s] - @o[:tl_1] + @o[:min_turn])**2 / @o[:s]

        @o[:cpi_bw_0] = @o[:base_cpi_0] * @o[:k] * @o[:b_0] * @o[:s] / @o[:a_0]
        @o[:cpi_bw_1] = @o[:base_cpi_1] * @o[:k] * @o[:b_1] * @o[:s] / @o[:a_1]

        @o[:cpi_0] = [@o[:cpi_lat_0],@o[:cpi_bw_0]].max
        @o[:cpi_1] = [@o[:cpi_lat_1],@o[:cpi_bw_1]].max

        # (@o[:base_cpi_0]/@o[:cpi_0] + @o[:base_cpi_1]/@o[:cpi_1])
        @o[:cpi_0] + @o[:cpi_1]
    end

    def energy
        @o[:tl_0] = @o[:k] * (@o[:a_0] - 1) + @o[:d]
        @o[:tl_1] = @o[:k] * (@o[:a_1] - 1) + @o[:d]
        @o[:s] = @o[:tl_0] + @o[:tl_1]

        @o[:slowdown_lat_0] = 1 + @o[:base_cpi_0] * @o[:b_0] / 2 *
           @o[:f] * (@o[:s] - @o[:tl_0] + @o[:d])**2 / @o[:s]
        @o[:slowdown_lat_1] = 1 + @o[:base_cpi_1] * @o[:b_1] / 2 *
           @o[:f] * (@o[:s] - @o[:tl_1] + @o[:d])**2 / @o[:s]
        
        @o[:slowdown_bw_0] = [@o[:s] * @o[:b_0] / @o[:a_0], 1].min
        @o[:slowdown_bw_1] = [@o[:s] * @o[:b_1] / @o[:a_1], 1].min

        @o[:cpi_0] = @o[:base_cpi_0] * @o[:slowdown_lat_0] * @o[:slowdown_bw_0]
        @o[:cpi_1] = @o[:base_cpi_1] * @o[:slowdown_lat_1] * @o[:slowdown_bw_1]

        [@o[:cpi_0], @o[:cpi_1]].max

    end
    
    
    def to_s() @o.to_s end

    # randomly generate a state
    def self.shuffle o
        State.new o.merge(
            a_0: (200.times.to_a).sample,
            a_1: (200.times.to_a).sample
        )
    end

    # randomly generate a neighboring state
    def neighbor
        var = @params.sample
        val = @o[var] + @deltas.sample
        val = val <= 0 ?  1 : val
        State.new @o.merge(var => val)
    end


end

class ReverseState
    def initialize o = {}
        @o = {
            #Helpful reminder of workload
            name: "nothing", 

            # input parameters
            k: 8,
            d: 23,
            f: 0.8,

            # enqueue rate in accesses per cycle
            b_0: 1,
            b_1: 1,

            # cpi in memory cycles per instruction
            base_cpi_0: 1,
            base_cpi_1: 1,

            # turn length 
            tl_0: 1,
            tl_1: 1
        }.merge o

        # variables that can be controlled
        @params = [ :a_0, :a_1 ] 

        # step variables
        @deltas = (-3..3).to_a

        # calc energy now so printing is accurate
        energy
    end

    def energy
        @o[:a_0] = (@o[:tl_0] - @o[:d]) / @o[:k] + 1
        @o[:a_1] = (@o[:tl_1] - @o[:d]) / @o[:k] + 1
        @o[:s] = @o[:tl_0] + @o[:tl_1]

        @o[:slowdown_lat_0] = 1 + @o[:base_cpi_0] * @o[:b_0] / 2 *
           @o[:f] * (@o[:s] - @o[:tl_0] + @o[:d])**2 / @o[:s]
        @o[:slowdown_lat_1] = 1 + @o[:base_cpi_1] * @o[:b_1] / 2 *
           @o[:f] * (@o[:s] - @o[:tl_1] + @o[:d])**2 / @o[:s]
        
        @o[:slowdown_bw_0] = [@o[:s] * @o[:b_0] / @o[:a_0], 1].min
        @o[:slowdown_bw_1] = [@o[:s] * @o[:b_1] / @o[:a_1], 1].min

        @o[:cpi_0] = @o[:base_cpi_0] * @o[:slowdown_lat_0] * @o[:slowdown_bw_0]
        @o[:cpi_1] = @o[:base_cpi_1] * @o[:slowdown_lat_1] * @o[:slowdown_bw_1]

        [@o[:cpi_0], @o[:cpi_1]].max
    end
    
    
    def to_s() @o.to_s end

    # randomly generate a state
    def self.shuffle o
        State.new o.merge(
            a_0: (200.times.to_a).sample,
            a_1: (200.times.to_a).sample
        )
    end

    # randomly generate a neighboring state
    def neighbor
        var = @params.sample
        val = @o[var] + @deltas.sample
        val = val <= 0 ?  1 : val
        State.new @o.merge(var => val)
    end
end
