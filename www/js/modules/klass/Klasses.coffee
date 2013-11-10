class Klasses extends Backbone.Collection
  model : Klass
  url   : 'klass'
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  byCollection
        key:  'klass'
