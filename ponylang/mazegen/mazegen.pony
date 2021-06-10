
use "random"

trait val Direction
    fun val move(x: USize, y: USize): (USize, USize)
    fun val can_move(x: USize, y: USize, w: USize, h: USize): Bool
    fun val update_cells(base_cell: Cell, to_cell: Cell): (Cell, Cell)
    fun box string(): String iso^

primitive Up is Direction
    fun val can_move(x: USize, y: USize, w: USize, h: USize): Bool => y != 0
    fun val move(x: USize, y: USize): (USize, USize) => (x, y-1)
    fun val update_cells(base_cell: Cell, to_cell: Cell): (Cell, Cell) =>
        (
            Cell.create(false, base_cell.wall_left, true),
            Cell.create(to_cell.wall_up, to_cell.wall_left, false)
        )
    fun box string(): String iso^ => recover iso String.create().>append("Up") end

primitive Down is Direction
    fun val can_move(x: USize, y: USize, w: USize, h: USize): Bool => (y+1) != h
    fun val move(x: USize, y: USize): (USize, USize) => (x, y+1)
    fun val update_cells(base_cell: Cell, to_cell: Cell): (Cell, Cell) =>
        (
            Cell.create(base_cell.wall_up, base_cell.wall_left, true),
            Cell.create(false, to_cell.wall_left, false)
        )
    fun box string(): String iso^ => recover iso String.create().>append("Down") end

primitive Left is Direction
    fun val can_move(x: USize, y: USize, w: USize, h: USize): Bool => x != 0
    fun val move(x: USize, y: USize): (USize, USize) => (x-1, y)
    fun val update_cells(base_cell: Cell, to_cell: Cell): (Cell, Cell) =>
        (
            Cell.create(base_cell.wall_up, false, true),
            Cell.create(to_cell.wall_up, to_cell.wall_left, false)
        )
    fun box string(): String iso^ => recover iso String.create().>append("Left") end

primitive Right is Direction
    fun val can_move(x: USize, y: USize, w: USize, h: USize): Bool => (x+1) != w
    fun val move(x: USize, y: USize): (USize, USize) => (x+1, y)
    fun val update_cells(base_cell: Cell, to_cell: Cell): (Cell, Cell) =>
        (
            Cell.create(base_cell.wall_up, base_cell.wall_left, true),
            Cell.create(to_cell.wall_up, false, false)
        )
    fun box string(): String iso^ => recover iso String.create().>append("Right") end

class val Cell
    let wall_up: Bool
    let wall_left: Bool
    let visited: Bool
    new val create(wu': Bool = true, wl': Bool = true, visited': Bool = true) =>
        wall_up = wu'
        wall_left = wl'
        visited = visited'
    fun box eq(that: Cell): Bool =>
        (wall_left == that.wall_left)
            and (wall_up == that.wall_up)
            and (visited == that.visited)
    fun box ne(that: Cell): Bool val => not eq(that)
    fun box string(): String iso^ =>
        recover iso String.create()
            .>append("Cell[")
            .>append("wall_up: ").>append(wall_up.string())
            .>append(", wall_left: ").>append(wall_left.string())
            .>append(", visited: ").>append(visited.string())
            .>append("]") end

class Maze
    let width: USize
    let height: USize

    let cells: Array[Cell] iso

    new create(w: USize, h: USize) =>
        width = w
        height = h
        let cells' = recover iso Array[Cell] end
        for y in IntIter(height) do
            for x in IntIter(width) do
                cells'.push(Cell.create(true, true, false))
            end
        end
        cells = consume cells'

    fun ref options_from(x: USize, y: USize): Array[Direction val] val =>
        let result: Array[Direction val] trn = recover trn Array[Direction val] end
        for direction in [Up; Down; Left; Right].values() do
            if direction.can_move(x, y, width, height) then
                result.push(direction)
            end
        end
        consume result

    fun ref generate(start_x: USize, start_y: USize, rand: Random) =>
        try
            let option = options_from(start_x, start_y)(0)?
            @printf[None]("option: %s\n".cstring(), option.string().cstring())
            let next_location = option.move(start_x, start_y)
            @printf[None]("This location (%s, %s)\n".cstring(), start_x.string().cstring(), start_y.string().cstring())
            @printf[None]("Next location (%s, %s)\n".cstring(), next_location._1.string().cstring(), next_location._2.string().cstring())
            let next_cells = option.update_cells(
                cell(start_x, start_y)?,
                cell(next_location._1, next_location._2)?
            )
            cells(index_for(start_x, start_y))? = next_cells._1
            cells(index_for(next_location._1, next_location._2))? = next_cells._2
        end


        // let queue = Array[(USize, USize)]
        // queue.push( (start_x, start_y) )
        // while queue.size() > 0 do
        //     let current = queue.pop()?
        //     let options = options_from(current._1, current._y)
        //     if options.size > 0 then

        //     end
        // end

        None

    fun ref index_for(x: USize, y: USize): USize =>
        (y*width) + x

    fun ref cell(x: USize, y: USize): Cell ? =>
        cells( index_for(x, y) )?

    fun ref render(): String val =>
        let result: String trn = recover trn String end

        for y in IntIter(height) do
            for x in IntIter(width) do
                if (try cell(x,y)?.wall_up else false end) then
                    result.append("*-")
                else
                    result.append("* ")
                end
            end
            result.append("*\n")
            for x in IntIter(width) do
                if (try cell(x,y)?.wall_left else false end) then
                    result.append("| ")
                else
                    result.append("  ")
                end
            end
            result.append("|\n")
        end
        for x in IntIter(width) do
            result.append("*-")
        end
        result.append("*")

        consume result

class ref IntIter is Iterator[USize]
    var _cur: USize
    var _max: USize
    var _has_next: Bool = true

    new ref create(to: USize) =>
        _cur = 0
        _max = to

    fun ref has_next(): Bool =>
        _cur < _max

    fun ref next(): USize =>
        let r = _cur
        _cur = _cur + 1
        r
