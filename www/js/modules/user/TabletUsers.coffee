class TabletUsers extends Backbone.Collection
  model: TabletUser
  url : 'user'
  pouch:
    fetch: 'query'
    options:
      query:
        fun:  byCollection
        key:  'user'

