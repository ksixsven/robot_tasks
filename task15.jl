# Задача 15. Поиск маркера на неограниченном поле с перегородками
# (отрезки, лучи, прямоугольники) - спираль с обходом перегородок.

using GLMakie
using HorizonSideRobots

"""
task15!(robot)

ДАНО:
    -- Робот находится на неограниченном поле, на котором есть перегородки
       (отрезки, лучи, прямоугольники); где-то на поле стоит маркер.

РЕЗУЛЬТАТ:
    -- Робот стоит в клетке с маркером.

Робот идёт по раскручивающейся спирали, обходя перегородки, и помнит свои
координаты относительно старта в неизменяемом именованном кортеже
position = (x = ..., y = ...): каждый шаг возвращает новую позицию.
"""
function task15!(robot)
    position = (x = 0, y = 0)
    prev_side, prev_target = Ost, 0     # предыдущий отрезок спирали
    target = 1                          # координата конца очередных отрезков
    #ИНВАРИАНТ: маркер не найден в клетках, пройденных по спирали
    while !ismarker(robot)
        for side in (Nord, West, Sud, Ost)
            position = move_leg!(robot, side, target, prev_side, prev_target, position)
            prev_side, prev_target = side, target
        end
        target += 1
    end
end

"""
move_leg!(robot, side, target, prev_side, prev_target, position)

ДАНО:
    -- Робот на спирали в позиции position; prev_side, prev_target -
       направление и конечная координата предыдущего отрезка спирали.

РЕЗУЛЬТАТ:
    -- Робот дошёл в направлении side до координаты target (или остановился
       раньше, найдя маркер); возвращена его новая позиция.
    -- Если обход прямоугольника увёл Робота за угол спирали, он сначала
       возвращается на линию предыдущего отрезка.
"""
function move_leg!(robot, side, target, prev_side, prev_target, position)
    position = return_to_line!(robot, prev_side, prev_target, position)
    #ИНВАРИАНТ: в клетке Робота маркера нет и отрезок не закончен
    while !ismarker(robot) && coord(position, side) < target
        position = step_bypass!(robot, side, position)
        position = return_to_line!(robot, prev_side, prev_target, position)
    end
    return position
end

"""
return_to_line!(robot, prev_side, prev_target, position)

Возвращает Робота к линии предыдущего отрезка спирали (если обход прямоугольника
увёл его дальше), останавливаясь, если найден маркер или впереди рамка прямоугольника.
Возвращает новую позицию.
"""
function return_to_line!(robot, prev_side, prev_target, position)
    while !ismarker(robot) && coord(position, prev_side) > prev_target && !isborder(robot, inverse(prev_side))
        position = go!(robot, inverse(prev_side), position)
    end
    return position
end

"""
step_bypass!(robot, side, position)

Делает шаг в направлении side с обходом перегородки.
Конец перегородки ищется "челноком" в обе стороны (нужно для лучей).
Робот возвращается на исходную линию; возвращена новая позиция.
"""
function step_bypass!(robot, side, position)
    if !isborder(robot, side)
        return go!(robot, side, position)
    end
    d = left(side)
    num_steps = 1
    shift = 0                   # смещение вдоль перегородки (+ налево, - направо)
    while isborder(robot, side)
        for _ in 1:num_steps
            position = go!(robot, d, position)
            shift += d == left(side) ? 1 : -1
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2          # удвоение длины захода, как в задаче 13
    end
    back = shift > 0 ? right(side) : left(side)
    position = go!(robot, side, position)
    while isborder(robot, back) # для прямоугольника - идём вдоль его стороны
        position = go!(robot, side, position)
    end
    for _ in 1:abs(shift)       # возвращаемся на исходную линию
        position = go!(robot, back, position)
    end
    return position
end

# Координаты Робота относительно старта

# Смещение (dx, dy) для Nord, West, Sud, Ost - в порядке значений HorizonSide
const DELTA = ((0, 1), (-1, 0), (0, -1), (1, 0))

"""
delta(side)

Возвращает смещение (dx, dy) клетки при шаге в направлении side
"""
delta(side) = DELTA[Int(side) + 1]

"""
go!(robot, side, position)

Делает шаг в направлении side и возвращает новую позицию
(position - неизменяемый кортеж (x = ..., y = ...))
"""
function go!(robot, side, position)
    move!(robot, side)
    dx, dy = delta(side)
    return (x = position.x + dx, y = position.y + dy)
end

"""
coord(position, side)

Возвращает координату позиции position вдоль направления side
"""
function coord(position, side)
    dx, dy = delta(side)
    return dx * position.x + dy * position.y
end

"""
right(side::HorizonSide)::HorizonSide

Возвращает направление направо относительно заданного
"""
right(side::HorizonSide) = HorizonSide(mod(Int(side) + 3, 4))

"""
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

"""
inverse(side::HorizonSide)::HorizonSide

Возвращает направление, противоположное заданному
"""
inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))

# Запуск: julia task15.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task15.sit"), animate = true)
    task15!(robot)
end
