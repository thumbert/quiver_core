

Code that determines DateTime tick locations in plotly.js

Main tick placement and spacing logic: axes.calcTicks, axes.autoTicks, axes.tickFirst, axes.tickIncrement
File: src/plots/cartesian/axes.js:951-1320 (calcTicks)
File: axes.js:1446-1560 (autoTicks)
File: axes.js:1560-1720 (tickIncrement, tickFirst)
Date utilities used by the above (date parsing, canonical tick0, month increment):
dateTick0: src/lib/dates.js:41
dateTime2ms: dates.js:140
incrementMonth: dates.js:514
Input validation for dtick / tick0 (affects where ticks start and their spacing):
src/plots/clean_ticks.js:1-120
Relevant tests

Date parsing, canonical ticks, month increment, ms↔date conversions: test/jasmine/tests/lib_date_test.js:1-260
Many axis/date-related behaviors (rangebreaks, tick formats, dtick cases) are exercised in:
test/jasmine/tests/axes_test.js:5000-5160 (date-related tests / rangebreaks)
test/jasmine/tests/localize_test.js:70-120 (date dtick formatting)

Other tests referencing Lib.dateTime2ms and dtick: histogram_test.js, plot_api_test.js, plot_api_react_test.js (search for dateTime2ms / dtick in tests).

