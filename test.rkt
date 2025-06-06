#lang reader "./caffeine/lang/reader.rkt"

(test-suite "Caffeine Language Tests")

(test-equal (slo "Vanilla") "SLO: Vanilla" "SLO: Vanilla")
(test-equal (slo "Espresso") "SLO: Espresso" "SLO: Espresso")
(test-equal (slo "Latte") "SLO: Latte" "SLO: Latte")

(run-tests)
