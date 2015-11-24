$(document).ready(() ->

  UP = 'up'
  RIGHT = 'right'
  DOWN = 'down'
  LEFT = 'left'

  class Grid
    constructor: (@width, @height, @element) ->
      @machines = (null for [1..(@width * @height)])
      @edges = (null for [1..(@width + @height + 2 * @width * @height)])

      for y in [0..@height]
        row = $('<div/>', {class: 'row'})
        for x in [0..@width]
          cell = $('<div/>', {class: 'cell'})
          if x < @width and y < @height
            cell.append($('<div/>', {class: 'slot', id: 'slot' + @toMachineIndex(x, y)}))
          for dir in [LEFT, UP]
            cell.append($('<div/>', {class: 'number', id: 'number' + @toEdgeIndex(x, y, dir)}))
          row.append(cell)
        @element.append(row)

    getMachine: (x, y) ->
      @machines[@toMachineIndex(x, y)]

    setMachine: (x, y, value) ->
      index = @toMachineIndex(x, y)
      @machines[index] = value

      slot = $('#slot' + index)
      slot.find('.machine').remove()
      slot.append(@machines[index].paint())

      @machines[index]

    toMachineIndex: (x, y) ->
      x + y * @width

    getEdge: (x, y, dir) ->
      @edges[@toEdgeIndex(x, y, dir)]

    setEdge: (x, y, dir, value) ->
      edge_index = @toEdgeIndex(x, y, dir)
      @element.find('#number'+edge_index).text(if value? then value else '')
      @edges[edge_index] = value

    toEdgeIndex: (x, y, dir) ->
      if dir == UP
        return (x + y * (@width + 1)) * 2 + 1
      else if dir == LEFT
        return (x + y * (@width + 1)) * 2
      else if dir == RIGHT
        return @toEdgeIndex(x + 1, y, LEFT)
      else if dir == DOWN
        return @toEdgeIndex(x, y + 1, UP)

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
                if @getEdge(x, y, value)
                  jammed = true
              if not jammed
                for value, i in machine.contents
                  @setEdge(x, y, machine.outputs[i], value)
                machine.contents = null


  class Machine
    constructor: (@inputs = [], @outputs = [], @function = ((i) -> i)) ->
      @contents = null

    paint: () ->
      element = $('<div/>', {class: 'machine'})

      for [list, name] in [[@inputs, 'input'], [@outputs, 'output']]
        for dir in [UP, DOWN, LEFT, RIGHT]
          if dir in list
            element.append($('<div/>', {class: 'port ' + name + ' ' + dir}))

      return element

  grid = new Grid(5, 5, $('.grid'))

  #Produder
  grid.setMachine(1, 1, new Machine([], [DOWN],
    () ->
      if @t?
        @t = null
      else
        @t = [Math.floor(Math.random() * 10)]
  ))
  #Splitter
  grid.setMachine(1, 2, new Machine([UP], [DOWN, RIGHT], (i) -> i.concat(i)))
  #Doubler
  grid.setMachine(2, 2, new Machine([LEFT], [DOWN], (i) -> i.map((a) -> a * 2)))
  #Conveyer
  grid.setMachine(1, 3, new Machine([UP], [RIGHT]))
  #Adder
  grid.setMachine(2, 3, new Machine([UP, LEFT], [RIGHT], (i) -> [i.reduce((a, b) -> (a + b))]))
  #Consumer
  grid.setMachine(3, 3, new Machine([LEFT]))

  setInterval(() ->
    grid.update()
  , 1000)
)