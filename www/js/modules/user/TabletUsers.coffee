class TabletUsers extends Backbone.Collection
  model: TabletUser
  url : 'user'
  pouch:
    query:
      fun:
        map: (doc) -> emit(doc.collection, doc) if doc.collection
    limit: 10
#  TabletUser.prototype.pouch.options = fetchOptions
