# Задача 10. Число маркеров на поле без перегородок

using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side) = HorizonSide(mod(Int(side) + 2, 4))

left(side) = HorizonSide(mod(Int(side) + 1, 4))

function move!(robot, side, num_steps)
    for _ in 1:num_steps
        move!(robot, side)
    end
end

function move_to_frame!(robot, side)
    while !isborder(robot, side)
        move!(robot, side)
    end
end

count_marker(robot) = Int(ismarker(robot))

# Идёт в сторону side до рамки, выполняя act после каждого шага.
function walk_to_frame!(robot, side, act)
    num_steps, total = 0, 0
    while !isborder(robot, side)
        move!(robot, side)
        total += act(robot)
        num_steps += 1
    end
    return (num_steps = num_steps, total = total)
end

# Шаг d вдоль стены, стоящей со стороны side, пока она не кончится.
function along_wall!(robot, side, d)
    num_steps = 0
    while isborder(robot, side) && !isborder(robot, d)
        move!(robot, d)
        num_steps += 1
    end
    return num_steps
end

# Робот стоит сбоку от конца перегородки: переходит на другую сторону,
# проходит вдоль неё и возвращается на исходную линию.
function pass_wall!(robot, side, d, num_steps)
    move!(robot, side)
    num_advance = 1
    while isborder(robot, inverse(d))
        move!(robot, side)
        num_advance += 1
    end
    move!(robot, inverse(d), num_steps)
    return num_advance
end

# Шаг в сторону side с обходом перегородки.
# Возвращает, на сколько клеток продвинулся Робот (0 - впереди внешняя рамка).
function move_bypass!(robot, side)
    if !isborder(robot, side)
        move!(robot, side)
        return 1
    end
    d = left(side)
    num_steps = along_wall!(robot, side, d)
    if isborder(robot, side)
        move!(robot, inverse(d), num_steps)
        return 0
    end
    return pass_wall!(robot, side, d, num_steps)
end

function move_bypass!(robot, side, num_steps)
    for _ in 1:num_steps
        move_bypass!(robot, side)
    end
end

# В юго-западный угол с обходом перегородок.
# Возвращает данные для обратного пути.
function to_corner!(robot)
    num_west, num_south = 0, 0
    at_frame = false
    while !at_frame
        if !isborder(robot, West)
            move!(robot, West)
            num_west += 1
        else
            num_south = along_wall!(robot, West, Sud)
            at_frame = isborder(robot, West)
            if !at_frame
                pass_wall!(robot, West, Sud, num_south)
                num_west += 1
            end
        end
    end
    return (num_west = num_west, num_south = num_south)
end

# Обход поля змейкой, начиная с юго-западного угла.
function walk_snake!(robot, act)
    total = act(robot)
    row = walk_to_frame!(robot, Ost, act)
    width = row.num_steps
    total += row.total
    x, side, num_up = width, West, 0
    while !isborder(robot, Nord)
        move!(robot, Nord)
        num_up += 1
        total += act(robot)
        target = side == Ost ? width : 0
        while x != target
            k = move_bypass!(robot, side)
            x += side == Ost ? k : -k
            total += act(robot)
        end
        side = inverse(side)
    end
    return (num_up = num_up, total = total)
end

function back_from_snake!(robot, num_up, num_west, num_south)
    move_to_frame!(robot, West)
    move!(robot, Sud, num_up - num_south)
    move_bypass!(robot, Ost, num_west)
end

function task10!(robot)
    num_west, num_south = to_corner!(robot)
    snake = walk_snake!(robot, count_marker)
    back_from_snake!(robot, snake.num_up, num_west, num_south)
    return snake.total
end
