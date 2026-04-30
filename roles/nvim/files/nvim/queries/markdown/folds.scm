; Folds a section of the document that starts with a heading
((section
    (atx_heading)) @fold
    (#trim! @fold))

; Folds lists and their items
(list
  (list_item) @fold
  (#trim! @fold))

; Folds nested list items
(list_item
  (list) @fold
  (#trim! @fold))
