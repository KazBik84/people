class Hrguru.Views.ScheduledUsersCollectionView extends Marionette.CollectionView
  el: ('#scheduled-users')
  tagName: 'tbody'

  itemView: Hrguru.Views.ScheduledUsersRow

  events:
    "click .up" : "increasingDirection"
    "click .down" : "decreasingDirection"

  initialize: (@collection) ->
    @on('collection:rendered', H.addUserIndex)
    @listenTo(EventAggregator, 'scheduledUsers:sort', @sort)
    @listenTo(EventAggregator, 'scheduledUsers:render', @render)

  increasingDirection: (e) ->
    @toggleClass(e.target)
    @collection.sortDirection = 1
    @sort(e.target.dataset.sort, @collection.sortDirection)

  decreasingDirection: (e) ->
    @toggleClass(e.target)
    @collection.sortDirection = 0
    @sort(e.target.dataset.sort, @collection.sortDirection)

  sort: (value = 'name', direction = 1) ->
    @collection.sortUsers(value, direction)
    @render()
    EventAggregator.trigger('users:updateVisibility', @getSelectizeData())

  toggleClass: (target) ->
    @$('.active').removeClass('active')
    $(target).addClass('active')

  onRender: ->
    @$el.find('th').each ->
      $th = $(this)
      $th.toggle(H.columnInCurrentSchedulingCategory($th.data('name')))

  getSelectizeData: ->
    data = {}
    _.each $('.selectized'), (element) ->
      data[$(element).attr('name')] = $(element)[0].selectize.items
    data