#lang reader "./caffeine/lang/reader.rkt"

(test-suite "Caffeine Language Tests")

(test-equal (slo "Vanilla" "99.99") "SLO: Vanilla 99.99" "SLO: Vanilla 99.99")
(test-equal (slo "Espresso" "99.99") "SLO: Espresso 99.99" "SLO: Espresso 99.99")
(test-equal (slo "Latte" "99.99") "SLO: Latte 99.99" "SLO: Latte 99.99")

(run-tests)
