Dir['*rb'].each { |f| require_relative f }
require 'colored'

def anneal name, b_0, b_1
    simulate_annealing(
        # max_time: 300_000_000,
        max_time: 30_000_000,
        init: lambda do
            State.new(
                name: name,
                a_0: 6,
                a_1: 6,
                b_0: b_0,
                b_1: b_1,
            )
        end
    )
end

if __FILE__ == $0
  DEBUG_S = false 
  # anneal "ast_ast", 2.2874734569703978e-06, 2.2874734569703978e-06
  # anneal "ast_h264", 2.2874734569703978e-06, 6.667726758359254e-05
  # anneal "h264_hmm", 6.667726758359254e-05, 0.008607927894127601
  # anneal "sjg_h264", 0.001904344228075362, 6.667726758359254e-05
  # anneal "sjg_sgj",  0.001904344228075362, 0.001904344228075362
  # anneal "mcf_ast",  0.01190772467199294, 2.2874734569703978e-06
  anneal "lib_ast",  0.03627124301407827,  2.2874734569703978e-06
  # anneal "mcf_mcf",  0.01190772467199294, 0.01190772467199294
  anneal "mcf_lib",  0.01190772467199294, 0.03627124301407827
  anneal "lib_lib", 0.03627124301407827, 0.03627124301407827
end
