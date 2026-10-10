# Задача 15. Маркер на неограниченном поле с перегородками

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side) = HorizonSide(mod(Int(side) + 2, 4))

left(side) = HorizonSide(mod(Int(side) + 1, 4))

right(side) = HorizonSide(mod(Int(side) + 3, 4))

const DELTA = ((0, 1), (-1, 0), (0, -1), (1, 0))   # Nord, West, Sud, Ost

delta(side) = DELTA[Int(side) + 1]

function go!(robot, side, position)
    move!(robot, side)
    dx, dy = delta(side)
    return (x = position.x + dx, y = position.y + dy)
end

function coord(position, side)
    dx, dy = delta(side)
    return dx * position.x + dy * position.y
end

function return_to_line!(robot, prev_side, prev_target, position)
    while !ismarker(robot) && coord(position, prev_side) > prev_target &&
          !isborder(robot, inverse(prev_side))
        position = go!(robot, inverse(prev_side), position)
    end
    return position
end

# Шаг с обходом перегородки; конец ищется "челноком" в обе стороны (для лучей).
function step_bypass!(robot, side, position)
    if !isborder(robot, side)
        return go!(robot, side, position)
    end
    d = left(side)
    num_steps = 1
    shift = 0
    while isborder(robot, side)
        for _ in 1:num_steps
            position = go!(robot, d, position)
            shift += d == left(side) ? 1 : -1
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2
    end
    back = shift > 0 ? right(side) : left(side)
    position = go!(robot, side, position)
    while isborder(robot, back)
        position = go!(robot, side, position)
    end
    for _ in 1:abs(shift)
        position = go!(robot, back, position)
    end
    return position
end

function move_leg!(robot, side, target, prev_side, prev_target, position)
    position = return_to_line!(robot, prev_side, prev_target, position)
    while !ismarker(robot) && coord(position, side) < target
        position = step_bypass!(robot, side, position)
        position = return_to_line!(robot, prev_side, prev_target, position)
    end
    return position
end

function task15!(robot)
    position = (x = 0, y = 0)
    prev_side, prev_target = Ost, 0
    target = 1
    while !ismarker(robot)
        for side in (Nord, West, Sud, Ost)
            position = move_leg!(robot, side, target, prev_side, prev_target, position)
            prev_side, prev_target = side, target
        end
        target += 1
    end
end

# Запуск с анимацией на поле-примере из fields/
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "..", "fields", "task15.sit"), animate = true)
    task15!(robot)
end
