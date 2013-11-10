class Results extends Backbone.Collection

  url : "result"
  model : Result
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  resultsByAssessmentId

  comparator: (model) ->
    model.get('start_time') || 0

  # By default include the docs
  fetch: (options) ->
    options = {} unless options?
    options.include_docs = true unless options.include_docs?
    super(options)
