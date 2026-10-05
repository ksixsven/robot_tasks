# Задача 15. Поиск маркера на неограниченном поле с перегородками
# (отрезки, лучи, прямоугольники) - спираль с обходом перегородок.
include("lib.jl")

"""
task15!(robot)

ДАНО:
    -- Робот находится на неограниченном поле, на котором есть перегородки
       (отрезки, лучи, прямоугольники); где-то на поле стоит маркер.

РЕЗУЛЬТАТ:
    -- Робот стоит в клетке с маркером.

Робот идёт по раскручивающейся спирали, обходя перегородки, и помнит свои
координаты position = [x, y] относительно старта.
"""
function task15!(robot)
    position = [0, 0]
    prev_side, prev_target = Ost, 0     # предыдущий отрезок спирали
    target = 1                          # координата конца очередных отрезков
    #ИНВАРИАНТ: маркер не найден в клетках, пройденных по спирали
    found = false
    while !found
        for side in (Nord, West, Sud, Ost)
            found = found || move_leg!(robot, side, target, prev_side, prev_target, position)
            prev_side, prev_target = side, target
        end
        target += 1
    end
end

"""
move_leg!(robot, side, target, prev_side, prev_target, position)

ДАНО:
    -- Робот на спирали; prev_side, prev_target - направление и конечная
       координата предыдущего отрезка спирали.

РЕЗУЛЬТАТ:
    -- Робот дошёл в направлении side до координаты target (или остановился
       раньше, найдя маркер); возвращено true, если найден маркер.
    -- Если обход прямоугольника увёл Робота за угол спирали, он сначала
       возвращается на линию предыдущего отрезка.
"""
function move_leg!(robot, side, target, prev_side, prev_target, position)
    return_to_line!(robot, prev_side, prev_target, position)
    #ИНВАРИАНТ: маркер в клетке Робота не найден (или найден - тогда цикл не идёт)
    while !ismarker(robot) && coord(position, side) < target
        step_bypass!(robot, side, position)
        return_to_line!(robot, prev_side, prev_target, position)
    end
    return ismarker(robot)
end

"""
return_to_line!(robot, prev_side, prev_target, position)

Возвращает Робота к линии предыдущего отрезка спирали (если обход прямоугольника
увёл его дальше), останавливаясь, если найден маркер или впереди рамка прямоугольника.
"""
function return_to_line!(robot, prev_side, prev_target, position)
    while !ismarker(robot) && coord(position, prev_side) > prev_target && !isborder(robot, inverse(prev_side))
        go!(robot, inverse(prev_side), position)
    end
end

"""
step_bypass!(robot, side, position)

Делает шаг в направлении side с обходом перегородки.
Конец перегородки ищется "челноком" в обе стороны (нужно для лучей).
Робот возвращается на исходную линию, координаты position обновляются.
"""
function step_bypass!(robot, side, position)
    if !isborder(robot, side)
        go!(robot, side, position)
        return
    end
    d = left(side)
    num_steps = 1
    shift = 0                   # смещение вдоль перегородки (+ налево, - направо)
    while isborder(robot, side)
        for _ in 1:num_steps
            go!(robot, d, position)
            shift += d == left(side) ? 1 : -1
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2          # удвоение длины захода, как в задаче 13
    end
    back = shift > 0 ? right(side) : left(side)
    go!(robot, side, position)
    while isborder(robot, back) # для прямоугольника - идём вдоль его стороны
        go!(robot, side, position)
    end
    for _ in 1:abs(shift)       # возвращаемся на исходную линию
        go!(robot, back, position)
    end
end

#-----------------------------------------------------------------------
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

Делает шаг в направлении side и обновляет координаты position = [x, y]
"""
function go!(robot, side, position)
    move!(robot, side)
    dx, dy = delta(side)
    position[1] += dx
    position[2] += dy
end

"""
coord(position, side)

Возвращает координату позиции position вдоль направления side
"""
function coord(position, side)
    dx, dy = delta(side)
    return dx * position[1] + dy * position[2]
end

# Запуск: julia task15.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task15.sit"), animate = true)
    task15!(robot)
end
