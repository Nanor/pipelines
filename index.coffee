$(document).ready(() ->

  X_SIZE = 9
  Y_SIZE = 5

  UP = 1
  RIGHT = 2
  DOWN = 3
  LEFT = 4

  class Grid
    constructor: (@width, @height) ->
      @machines = (null for [1..(@width * @height)])
      @edges = (null for [1..(@width + @height + 2 * @width * @height)])

    paint: (element) ->
      px = (X_SIZE + 1) * @width + 1
      py = (Y_SIZE + 1) * @height + 1
      chars = ((null for [1..px]) for [1..py])

      for x in [0...px]
        for y in [0...py]
          if x % (X_SIZE + 1) == 0 and y % (Y_SIZE + 1) == 0
            chars[y][x] = '+'

      for x in [1...@width]
        for y in [1...@height]
          machine = @getMachine(x, y)
          if machine?
            machine_chars = machine.paint()
            for px in [0...X_SIZE]
              for py in [0...Y_SIZE]
                chars[y * (Y_SIZE + 1) + py + 1][x * (X_SIZE + 1) + px + 1] = machine_chars[py][px]

      for x in [0...@width]
        for y in [0..@height]
          chars[y * (Y_SIZE + 1)][x * (X_SIZE + 1) + (X_SIZE + 1)//2] = @getEdge(x, y, UP)

      for x in [0..@width]
        for y in [0...@height]
          chars[y * (Y_SIZE + 1) + (Y_SIZE + 1) // 2][x * (X_SIZE + 1)] = @getEdge(x, y, LEFT)

      chars = (((if c? then c else ' ') for c in line) for line in chars)

      element.text((line.join('') for line in chars).join('\n'))

    getMachine: (x, y) ->
      @machines[@toMachineIndex(x, y)]

    setMachine: (x, y, value) ->
      @machines[@toMachineIndex(x, y)] = value

    toMachineIndex: (x, y) ->
      x + y * X_SIZE

    getEdge: (x, y, dir) ->
      @edges[@toEdgeIndex(x, y, dir)]

    setEdge: (x, y, dir, value) ->
      @edges[@toEdgeIndex(x, y, dir)] = value

    toEdgeIndex: (x, y, dir) ->
      if dir == UP
        return (x + y * X_SIZE) * 2
      else if dir == LEFT
        return (x + y * X_SIZE) * 2 + 1
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
      chars = (((if (y == 0 or y == Y_SIZE - 1) then '-' else if (x == 0 or x == X_SIZE - 1) then '|' else ' ') for x in [0...X_SIZE]) for y in [0...Y_SIZE])

      for [dir, y, x, in_c, out_c] in [
        [UP, 0, X_SIZE//2, 'V', '^'],
        [RIGHT, Y_SIZE//2, X_SIZE - 1, '<', '>'],
        [DOWN, Y_SIZE - 1, X_SIZE//2, '^', 'V'],
        [LEFT, Y_SIZE//2, 0, '>', '<'],
      ]
        chars[y][x] = if dir in @inputs then in_c else if dir in @outputs then out_c else chars[y][x]

      return chars

  grid = new Grid(5, 5)

  #Produder
  grid.setMachine(1, 1, new Machine([], [DOWN],
    () ->
      if @t?
        @t = null
      else
        @t = [Math.floor(Math.random() * 4)]
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

  grid.paint($('.grid'))
  setInterval(() ->
    grid.update()
    grid.paint($('.grid'))
  , 1000)
)