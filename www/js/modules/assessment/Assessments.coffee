class Assessments extends Backbone.Collection
  model: Assessment
  url: 'assessment'
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  byCollection
        key:  'assessment'
  comparator : (model) ->
    model.get "name"