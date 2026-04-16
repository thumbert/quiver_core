

# 2026-04-16
- Add a clearSelection function in AutocompleteUi to allow you to clear the selection. 

# 2026-03-23
- Reduce some of the vertical padding on the Term widgets from 10px to 8px.
- Do the same for the dropdown widgets
- Add a style argument to the dropdown widgets

# 2026-03-22
- Add specialized widgets based on TextField for a Date and Month input similar to 
  Term. 
- Allow empty content for the TermUi, MonthUi, DayUi widgets to allow clearing of 
  values.  Make that a feature under a boolean flag. 

# 2026-03-14
- Add autocomplete dropdown with multi select. 
- Improve performance of autocompleted dropdown (Claude).  

# 2026-03-06
- Basic legend working

# 2026-02-27
- Add dropdown to the core widgets
- Add term textfield to the core widgets (introduce dependencies on package date 
  and timezone)

# 2026-02-23
- First investigations of the graphic package to see if it can be 
a replacement for Plotly