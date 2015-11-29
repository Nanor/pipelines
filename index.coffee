$(document).ready(() ->

  uid = (()->
    id = 0
    return () ->
      return id++)()

  class Grid
    constructor: (@width, @height, @element) ->
      @slots = (null for [1..(@width * @height)])

      for y in [0..@height]
        row = $('<div/>', {class: 'row'})
        for x in [0..@width]
          cell = $('<div/>', {class: 'cell'})
          if x < @width and y < @height
            @slots[@toSlotIndex(x, y)] = new Slot(cell)
          row.append(cell)
        @element.append(row)

    getSlot: (x, y) ->
      @slots[@toSlotIndex(x, y)]

    toSlotIndex: (x, y) ->
      x + y * @width

  class PlayingGrid extends Grid
    constructor: (width, height, element) ->
      super(width, height, element)

      @edges = (null for [1..((@width + 1) * (@height + 1) * 2)])
      for row, y in @element.children('.row')
        for cell, x in $(row).children('.cell')
          for dir in ['left', 'up']
            $(cell).append($('<div/>', {class: 'number ' + dir, id: 'number-' + @toEdgeIndex(x, y, dir)}))

    getEdge: (x, y, dir) ->
      @edges[@toEdgeIndex(x, y, dir)]

    setEdge: (x, y, dir, value) ->
      edge_index = @toEdgeIndex(x, y, dir)
      @element.find('#number-' + edge_index).text(if value? then value else '')
      @edges[edge_index] = value

    toEdgeIndex: (x, y, dir) ->
      if dir == 'up'
        return (x + y * (@width + 1)) * 2 + 1
      else if dir == 'left'
        return (x + y * (@width + 1)) * 2
      else if dir == 'right'
        return @toEdgeIndex(x + 1, y, 'left')
      else if dir == 'down'
        return @toEdgeIndex(x, y + 1, 'up')

    update: () ->
      for x in [0...@width] #Input
        for y in [0...@height]
          machine = @getSlot(x, y).machine
          if machine?
            if not machine.contents?
              supplied = true
              for value in machine.inputs
                if not @getEdge(x, y, value)?
                  supplied = false
              if supplied
                machine.contents = (
                  for dir in machine.inputs
                    value = @getEdge(x, y, dir)
                    @setEdge(x, y, dir, null)
                    value)
                machine.contents = machine.function(machine.contents)

      for x in [0...@width] #Output
        for y in [0...@height]
          machine = @getSlot(x, y).machine
          if machine?
            if machine.contents?
              jammed = false
              for value in machine.outputs
                if @getEdge(x, y, value) != null
                  jammed = true
              if not jammed
                for value, i in machine.contents
                  @setEdge(x, y, machine.outputs[i], value)
                machine.contents = null

  class Inventory extends Grid
    constructor: (width, height, element) ->
      super(width, height, element)

    addMachine: (machine) ->
      freeSlots = (slot for slot in @slots when not slot.machine?)

      if freeSlots.length > 0
        freeSlots[0].moveMachine(machine)

  class Slot
    constructor: (parent_element) ->
      @machine = null
      parent_element.append(@_makeHtml())

    _makeHtml: () ->
      @element = $('<div/>', {
        class: 'slot',
        ondrop: 'window.dropSlot(event)',
        ondragover: 'event.preventDefault()',
      })
      @element.data('class', @)

    moveMachine: (machine) ->
      machineHtml = machine.getHtml()

      oldSlot = machineHtml.parent().data('class')
      if oldSlot?
        oldSlot.machine = null

      if not @machine?
        @machine = machine
        @element.append(machineHtml)

  class Machine
    constructor: (@inputs = [], @outputs = [], @function = ((i) -> i)) ->
      @contents = null
      @id = uid()

    getHtml: () ->
      if not @element?
        @element = $('<div/>', {
          class: 'machine',
          id: 'machine-' + @id,
          draggable: true,
          ondragstart: 'window.dragMachine(event)',
        })

        for [list, name] in [[@inputs, 'input'], [@outputs, 'output']]
          for dir in ['up', 'down', 'left', 'right']
            if dir in list
              @element.append($('<div/>', {class: 'port ' + name + ' ' + dir}))

        @element.data('class', @)

      return @element

  window.dragMachine = (e) ->
    e.dataTransfer.setData('text', e.target.id)

  window.dropSlot = (e) ->
    e.preventDefault()

    machineId = e.dataTransfer.getData('text')
    machine = $('#' + machineId).data('class')
    slot = $(e.target).data('class')

    if slot instanceof Slot
      slot.moveMachine(machine)

  grid = new PlayingGrid(5, 5, $('#grid'))
  inventory = new Inventory(2, 6, $('#inventory'))

  #Produder
  inventory.addMachine(new Machine([], ['down'],
    () ->
      if @t?
        @t = null
      else
        @t = (Math.floor(Math.random() * 10) for [1..@outputs.length])
  ))
  #Splitter
  inventory.addMachine(new Machine(['up'], ['down', 'right'], (i) -> i.concat(i)))
  #Doubler
  inventory.addMachine(new Machine(['left'], ['down'], (i) -> i.map((a) -> a * 2)))
  #Conveyer
  inventory.addMachine(new Machine(['up'], ['right']))
  #Adder
  inventory.addMachine(new Machine(['up', 'left'], ['right'], (i) -> [i.reduce((a, b) -> (a + b))]))
  #Consumer
  inventory.addMachine(new Machine(['left']))

  setInterval(() ->
    grid.update()
  , 1000)
)