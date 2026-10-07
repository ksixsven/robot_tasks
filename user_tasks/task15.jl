using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))
right(side::HorizonSide) = HorizonSide(mod(Int(side) + 3, 4))

function move_n!(robot, side, num_steps)
    for _ in 1:num_steps
        move!(robot, side)
    end
end

# Шаг в направлении side с обходом перегородки (конец перегородки ищется "челноком"
# в обе стороны - иначе Робот бесконечно идёт вдоль луча); возвращается на исходную линию
function try_move!(robot, side)::Int
    if !isborder(robot, side)
        move!(robot, side)
        return 1
    end
    d = left(side)
    num_steps = 1
    shift = 0                   # смещение вдоль перегородки (+ налево, - направо)
    while isborder(robot, side)
        for _ in 1:num_steps
            move!(robot, d)
            if ismarker(robot) return 0 end
            shift += d == left(side) ? 1 : -1
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2
    end
    back = shift > 0 ? right(side) : left(side)
    move!(robot, side)
    if ismarker(robot) return 1 end
    advance = 1                 # на сколько клеток Робот продвинулся вдоль side
    while isborder(robot, back) # для прямоугольника - идём вдоль его стороны
        move!(robot, side)
        advance += 1
        if ismarker(robot) return advance end
    end
    for _ in 1:abs(shift)
        move!(robot, back)
        if ismarker(robot) return advance end
    end
    return advance
end

# Смещения (dx, dy) для Nord, West, Sud, Ost - в порядке значений HorizonSide
const DELTA = ((0, 1), (-1, 0), (0, -1), (1, 0))

# Координата позиции pos = (x, y) вдоль направления side
function coord(pos, side)
    dx, dy = DELTA[Int(side) + 1]
    return dx * pos[1] + dy * pos[2]
end

# Шаг с обходом перегородки; возвращает новую позицию (обход прямоугольника
# может продвинуть Робота дальше одной клетки)
function step_bypass!(robot, side, pos)
    advance = try_move!(robot, side)
    dx, dy = DELTA[Int(side) + 1]
    return (pos[1] + advance * dx, pos[2] + advance * dy)
end

# Возвращает Робота на линию предыдущего отрезка спирали, если обход его с неё увёл
function return_to_line!(robot, prev_side, prev_target, pos)
    while !ismarker(robot) && coord(pos, prev_side) > prev_target && !isborder(robot, inverse(prev_side))
        move!(robot, inverse(prev_side))
        dx, dy = DELTA[Int(inverse(prev_side)) + 1]
        pos = (pos[1] + dx, pos[2] + dy)
    end
    return pos
end

# Отрезок спирали: идти в направлении side до координаты target (или до маркера)
function move_leg!(robot, side, target, prev_side, prev_target, pos)
    pos = return_to_line!(robot, prev_side, prev_target, pos)
    while !ismarker(robot) && coord(pos, side) < target
        pos = step_bypass!(robot, side, pos)
        pos = return_to_line!(robot, prev_side, prev_target, pos)
    end
    return pos
end

function find_marker_with_borders!(robot)
    pos = (0, 0)                        # координаты относительно старта
    prev_side, prev_target = Ost, 0     # предыдущий отрезок спирали
    target = 1
    while !ismarker(robot)
        for side in (Nord, West, Sud, Ost)
            pos = move_leg!(robot, side, target, prev_side, prev_target, pos)
            prev_side, prev_target = side, target
        end
        target += 1
    end
    return nothing
end

robot = Robot(animate=true)
find_marker_with_borders!(robot)
