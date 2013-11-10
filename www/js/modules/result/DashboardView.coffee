class DashboardView extends Backbone.View

  className : "DashboardView"

  events:
    "change #groupBy": "update"
    "change #assessment": "update"
    "change #shiftHours": "update"
    "click .result": "showResult"

  showResult: (event) =>
    view = this
    resultDetails = $("#resultDetails")
    if resultDetails.is(":visible")
      resultDetails.hide()
    else
      resultId = $(event.target).text()
      Tangerine.$db.get resultId, (err, result) ->
        if result
          resultDetails.html "<pre>#{view.syntaxHighlight(result)}</pre>"
          resultDetails.css
            top: $(event.target).position().top + 30
            width: 400
            left: 50
          resultDetails.show()
        else
          console.log("Error: " + err)

  syntaxHighlight: (json) =>
    window.json = json
    if (typeof json != 'string')
       json = JSON.stringify(json, undefined, 2)
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return json.replace /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, (match) ->
      cls = 'number'
      if (/^"/.test(match))
        if (/:$/.test(match))
          cls = 'key'
        else
          cls = 'string'
      else if (/true|false/.test(match))
        cls = 'boolean'
      else if (/null/.test(match))
        cls = 'null'
      return '<span class="' + cls + '">' + match + '</span>'

  update: =>
    Tangerine.router.navigate("dashboard/groupBy/#{$("#groupBy").val()}/assessment/#{$("#assessment").val()}/shiftHours/#{$("#shiftHours").val()}", true)

  render: =>
    options = @options
    @groupBy = options.groupBy
    @key = options.assessment
    @shiftHours = options.shiftHours || 0

    if @key is "All"
#      $.couch.db(Tangerine.db_name).view "#{Tangerine.design_doc}/dashboardResults",
      dbResults = new Results()
      dbResults.fetch
        fetch: 'query'
        options:
          query:
            fun:  dashboardResults
#        reduce: false
        success: @renderResults
    else
#      $.couch.db(Tangerine.db_name).view "#{Tangerine.design_doc}/dashboardResults",
      dbResults = new Results()
      dbResults.fetch
        fetch: 'query'
        options:
          query:
            fun:  dashboardResults
          key: @key
          reduce: false
        success: @renderResults

  renderResults: (result) =>
    tableRows = {}
    dates = {}
    propertiesToGroupBy = {}

    # Find the first possible grouping variable and use it if not defined
    @groupBy = _.keys(result.models[0].attributes)[0] unless @groupBy?

    _.each result.models, (model) =>
      leftColumn = model.get(@groupBy)
      sortingDate = if model.get('start_time') then moment(model.get('start_time')).add("h",@shiftHours).format("YYYYMMDD") else "Unknown"
      displayDate = if model.get('start_time') then moment(model.get('start_time')).add("h",@shiftHours).format("Do MMM") else "Unknown"
      dates[sortingDate] = displayDate
      tableRows[leftColumn] = {} unless tableRows[leftColumn]?
      tableRows[leftColumn][sortingDate] = [] unless tableRows[leftColumn][sortingDate]?
      tableRows[leftColumn][sortingDate].push "
        <div style='padding-top:10px;'>
          <table>
          #{
            _.map(model.attributes, (value,key) =>
              propertiesToGroupBy[key] = true
              value = moment(value).add("h",@shiftHours).format("YYYY-MM-DD HH:mm") if key is "start_time"
              value = "<button class='result'>#{value}</button>" if key is "_id"
              "<tr><td>#{key}</td><td>#{value}</td></tr>"
            ).join("")
          }
          </table>
        </div>
        <hr/>
      "
    @$el.html "
      <h1>#{Tangerine.settings.get("groupName")}</h1>
      Assessment:
      <select id='assessment'>
      </select>
      <br/>
      Value used for grouping:
      <select id='groupBy'>
        #{
          _.map propertiesToGroupBy, (value,key) =>
            "<option #{if key is @groupBy then "selected='true'" else ''}>
              #{key}
            </option>"
        }
      </select>
      <br/>
      <br/>
      <button onClick='$(\"#advancedOptions\").toggle()'>Advanced Options</button>
      <div style='display:none' id='advancedOptions'>
      Current time in your timezone (#{jstz.determine().name()}) is #{ moment().format("YYYY-MM-DD HH:mm") }<br/>
      Shift time values by <input id='shiftHours' type='number' value='#{@shiftHours}'></input> hours to handle correct timezone.<br/>
      Shifted time: #{ moment().add("h",@shiftHours).format("YYYY-MM-DD HH:mm")}
      <br/>
      </div>

      <table id='results' class='tablesorter'>
        <thead>
          <th>#{@groupBy}</th>
          #{
            _(dates).keys().sort().map( (sortingDate) ->
              "<th class='#{sortingDate}'>#{dates[sortingDate]}</th>"
            ).join("")
          }
        </thead>
        <tbody>
          #{
            _.map(tableRows, (dataForDates, leftColumn) ->
              "<tr>
                <td>#{leftColumn}</td>
                #{
                  _(dates).keys().sort().map( (sortingDate) ->
                    "<td class='#{sortingDate}'>
                      #{
                        if dataForDates[sortingDate]
                          "
                            <button class='sort-value' onClick='$(this).siblings().toggle()'>#{dataForDates[sortingDate].length}</button>
                            <div style='display:none'>
                              #{dataForDates[sortingDate].join("")}
                            </div>
                          "
                        else
                          ""
                      }
                    </td>"
                  ).join("")
                }
              </tr>"
            ).join("")
          }
        </tbody>
      </table>
      <div id='resultDetails'>
      </div>
      <style>
        #resultDetails{
          position:absolute;
          background-color:black;
          display:none;
        }
        pre {
          font-size: 75%;
          outline: 1px solid #ccc;
          padding: 5px;
          margin: 5px;
          text-shadow: none;
          overflow-wrap:break-word;
        }
        .string { color: green; }
        .number { color: darkorange; }
        .boolean { color: blue; }
        .null { color: magenta; }
        .key { color: red; }
      </style>
    "

    @$el.find("table#results").tablesorter
      widgets: ['zebra']
      sortList: [[0,0]]
      textExtraction: (node) ->
        sortValue = $(node).find(".sort-value").text()
        if sortValue != ""
          sortValue
        else
          $(node).text()

    @$el.find("#advancedOptions").append "Select which dates to show<br/>"
    _(dates).keys().sort().map( (sortingDate) =>
      displayDate = dates[sortingDate]
      dateCheckbox = $("<label for='#{sortingDate}'>#{displayDate}</label><input name='#{sortingDate}' id='#{sortingDate}' type='checkbox' checked='true'/>")
      dateCheckbox.click ->
        $(".#{sortingDate}").toggle()
      @$el.find("#advancedOptions").append dateCheckbox
    )
#  $.couch.db(Tangerine.db_name).view "#{Tangerine.design_doc}/dashboardResults",
    dbResults = new Results
    dbResults.fetch
      fetch: 'query'
      options:
        query:
          fun:  dashboardResults
      group: true
      success: (result) =>
#        _.each result.models, (model) =>
#        leftColumn = model.get(@groupBy)
        thisModel = result.models[0].attributes;
        modelKeys = _.keys(thisModel)
        $("select#assessment").html "<option>All</option>" +
#        _.map(result.models[0].attributes, (row) =>
#          "<option value='#{row.key}' #{if row.key is @key then "selected='true'" else ""}>#{row.key}</option>"
        _.map(modelKeys, (modelKey) =>
#          "<option value='#{row.key}' #{if row.key is @key then "selected='true'" else ""}>#{row.key}</option>"
          "<option value='#{modelKey}' #{if modelKey is @key then "selected='true'" else ""}>#{modelKey}</option>"
        ).join("")
#        _.each result.models, (model) =>
#          _.map(model.attributes, (value, key) =>
##          "<option value='#{row.key}' #{if row.key is @key then "selected='true'" else ""}>#{row.key}</option>"
#            $("option[value=#{key}]").html value
#          ).join("")
#          return unless row.key?
#          $.couch.db(Tangerine.db_name).openDoc row.key,
#            success: (result) =>
#              $("option[value=#{row.key}]").html result.name
#            error: (result) =>
#              $("option[value=#{row.key}]").html "Unknown assessment"


    @trigger "rendered"
