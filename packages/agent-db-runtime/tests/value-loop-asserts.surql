-- Agent DB Runtime value-loop assertions
-- Applied with: surreal import <conn> tests/value-loop-asserts.surql
-- Requires the value-loop smoke script (tests/value-loop-smoke.surql) to be applied first.
-- Uses THROW so `surreal import` exits non-zero when any value-loop stage produced no records.

LET $output = (SELECT count() AS count FROM output GROUP ALL)[0].count ?? 0;
IF $output < 1 { THROW "value-loop: no output records"; };

LET $outcome = (SELECT count() AS count FROM outcome GROUP ALL)[0].count ?? 0;
IF $outcome < 1 { THROW "value-loop: no outcome records"; };

LET $value = (SELECT count() AS count FROM value_realization GROUP ALL)[0].count ?? 0;
IF $value < 1 { THROW "value-loop: no value_realization records"; };

LET $learning = (SELECT count() AS count FROM learning GROUP ALL)[0].count ?? 0;
IF $learning < 1 { THROW "value-loop: no learning records"; };

LET $improvement = (SELECT count() AS count FROM improvement GROUP ALL)[0].count ?? 0;
IF $improvement < 1 { THROW "value-loop: no improvement records"; };

RETURN "value-loop ok: output, outcome, value_realization, learning, improvement present";
