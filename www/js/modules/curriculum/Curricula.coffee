class Curricula extends Backbone.Collection

  url : "curriculum"
  model : Curriculum
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  byCollection
        key:  'curriculum'
