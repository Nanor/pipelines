$(document).ready(() ->

  uid = (()->
    id = 0
    return () ->
      return id++)()

  class Grid
    constructor: (@width, @height, @element) ->
      @machines = (null for [1..(@width * @height)])
      @edges = (null for [1..(@width + @height + 2 * @width * @height)])

      for y in [0..@height]
        row = $('<div/>', {class: 'row'})
        for x in [0..@width]
          cell = $('<div/>', {class: 'cell'})
          if x < @width and y < @height
            cell.append($('<div/>', {
              class: 'slot',
              id: 'slot-' + @toMachineIndex(x, y),
              ondrop: 'window.dropSlot(event)',
              ondragover: 'event.preventDefault()',
            }))
          for dir in ['left', 'up']
            cell.append($('<div/>', {class: 'number ' + dir, id: 'number-' + @toEdgeIndex(x, y, dir)}))
          row.append(cell)
        @element.append(row)

    getMachine: (x, y) ->
      @machines[@toMachineIndex(x, y)]

    setMachine: (x, y, value) ->
      index = @toMachineIndex(x, y)
      @machines[index] = value

      slot = $('#slot-' + index)
      slot.find('.machine').remove()
      if @machines[index]?
        slot.append(@machines[index].paint())

      @machines[index]

    toMachineIndex: (x, y) ->
      x + y * @width

    fromMachineIndex: (i) ->
      [i % @width, i // @width]

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
#Input
      for x in [0...@width]
        for y in [0...@height]
          machine = @getMachine(x, y)
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
      #Output
      for x in [0...@width]
        for y in [0...@height]
          machine = @getMachine(x, y)
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

    move: (machineId, slotIndex) ->
      if slotIndex.split('-')[0] == 'slot'
        for machine, oldMachineIndex in @machines
          if machine? and machine.id == parseInt(machineId.split('-')[1])
            [oldX, oldY] = @fromMachineIndex(oldMachineIndex)
            [newX, newY] = @fromMachineIndex(slotIndex.split('-')[1])

            if not @getMachine(newX, newY)?
              @setMachine(newX, newY, @getMachine(oldX, oldY))
              @setMachine(oldX, oldY, null)

  class Machine
    constructor: (@inputs = [], @outputs = [], @function = ((i) -> i)) ->
      @contents = null
      @id = uid()

    paint: () ->
      element = $('<div/>', {
        class: 'machine',
        id: 'machine-' + @id,
        draggable: true,
        ondragstart: 'window.dragMachine(event)',
      })

      for [list, name] in [[@inputs, 'input'], [@outputs, 'output']]
        for dir in ['up', 'down', 'left', 'right']
          if dir in list
            element.append($('<div/>', {class: 'port ' + name + ' ' + dir}))

      return element

  window.dragMachine = (e) ->
    e.dataTransfer.setData('text', e.target.id)

  window.dropSlot = (e) ->
    e.preventDefault()
    machineId = e.dataTransfer.getData('text')
    slotId = e.target.id
    grid.move(machineId, slotId)

  grid = new Grid(5, 5, $('.grid'))

  #Produder
  grid.setMachine(1, 1, new Machine([], ['down'],
    () ->
      if @t?
        @t = null
      else
        @t = [Math.floor(Math.random() * 10)]
  ))
  #Splitter
  grid.setMachine(1, 2, new Machine(['up'], ['down', 'right'], (i) -> i.concat(i)))
  #Doubler
  grid.setMachine(2, 2, new Machine(['left'], ['down'], (i) -> i.map((a) -> a * 2)))
  #Conveyer
  grid.setMachine(1, 3, new Machine(['up'], ['right']))
  #Adder
  grid.setMachine(2, 3, new Machine(['up', 'left'], ['right'], (i) -> [i.reduce((a, b) -> (a + b))]))
  #Consumer
  grid.setMachine(3, 3, new Machine(['left']))

  setInterval(() ->
    grid.update()
  , 1000)
)