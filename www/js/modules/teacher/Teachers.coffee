class Teachers extends Backbone.Collection
  model : Teacher
  url : "teacher"
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  byCollection
        key:  'teacher'