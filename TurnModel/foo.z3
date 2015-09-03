; input parameters
(declare-const k Int)
(declare-const t_dead Int)
(declare-const b_0 Int)
(declare-const b_1 Int)

; parameter values
(assert (= t_dead 44))
(assert (> k 0))
(assert (> b_0 0))
(assert (> b_1 0))

; derived variables
(declare-const s Int)
(declare-const a_0 Int)
(declare-const a_1 Int)
(declare-const t_0 Int)
(declare-const t_1 Int)


; variable constraints
(assert (= s (+ t_0 t_1)))
(assert (= t_0 (+ t_dead (* k (- a_0 1) ))))
(assert (= t_1 (+ t_dead (* k (- a_1 1) ))))
(assert (= a_0 (* b_0 s)))
(assert (= a_1 (* b_1 s)))
(assert (> t_0 t_dead))
(assert (> t_1 t_dead))

(check-sat)
(get-model)
