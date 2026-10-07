# Задача 9. Подсчитать маркеры по периметру внешней рамки (есть перегородки)

using HorizonSideRobots
import HorizonSideRobots: move!

"""
task9!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля.
    -- Внутри поля есть изолированные перегородки, не касающиеся друг друга
       и внешней рамки; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров по периметру внешней рамки.
"""
function task9!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    num_markers = walk_perimeter!(robot, count_marker)
    #УТВ: маркеры периметра сосчитаны, Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return num_markers
end

#----------------------------------------------------------------------

"""
from_corner!(robot, num_west, num_south)

ДАНО:
    -- Робот в юго-западном углу; (num_west, num_south) - результат to_corner!

РЕЗУЛЬТАТ:
    -- Робот в исходной клетке (из которой был вызван to_corner!)
"""
function from_corner!(robot, num_west, num_south)
    move!(robot, Nord, num_south)
    move_bypass!(robot, Ost, num_west)
end

#----------------------------------------------------------------------

"""
move_bypass!(robot, side)

Делает шаг в направлении side с обходом внутренней перегородки.
Возвращает, на сколько клеток Робот продвинулся (при обходе прямоугольника - больше 1),
или 0, если впереди внешняя рамка (Робот остаётся на месте).
"""
function move_bypass!(robot, side)
    if !isborder(robot, side)
        move!(robot, side)
        return 1
    end
    d = left(side)                      # направление обхода
    num_steps = along_wall!(robot, side, d)
    if isborder(robot, side)            # стена тянется до рамки - это внешняя рамка
        move!(robot, inverse(d), num_steps)
        return 0
    end
    return pass_wall!(robot, side, d, num_steps)
end

"""
move_bypass!(robot, side, num_steps)

Делает num_steps вызовов move_bypass!(robot, side)
"""
function move_bypass!(robot, side, num_steps)
    for _ in 1:num_steps
        move_bypass!(robot, side)
    end
end

#----------------------------------------------------------------------

"""
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

#----------------------------------------------------------------------

"""
to_corner!(robot)

ДАНО:
    -- Робот в произвольной клетке ограниченного поля (перегородки изолированы)

РЕЗУЛЬТАТ:
    -- Робот в юго-западном углу;
    -- возвращён именованный кортеж (num_west = число вызовов move_bypass! на запад,
       num_south = число шагов на юг) - по нему путь назад находит from_corner!.

Упёршись в стену, идём вдоль неё на юг, как move_bypass!. Если это рамка,
Робот при этом уже спустился в угол - возвращаться обратно незачем.
"""
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
    #УТВ: Робот - в юго-западном углу
    return (num_west = num_west, num_south = num_south)
end

#----------------------------------------------------------------------

"""
pass_wall!(robot, side, d, num_steps)

ДАНО:
    -- Робот сдвинут на num_steps шагов в направлении d и стоит сбоку
       от конца перегородки (в направлении side стены уже нет)

РЕЗУЛЬТАТ:
    -- Робот шагнул за перегородку, прошёл вдоль неё (если это прямоугольник,
       то вдоль его стороны) и вернулся на исходную линию;
    -- возвращено, на сколько клеток Робот продвинулся в направлении side.
"""
function pass_wall!(robot, side, d, num_steps)
    move!(robot, side)
    num_advance = 1
    while isborder(robot, inverse(d))   # вдоль прямоугольника, пока он не кончится
        move!(robot, side)
        num_advance += 1
    end
    move!(robot, inverse(d), num_steps) # назад на исходную линию
    return num_advance
end

#----------------------------------------------------------------------

"""
move!(robot, side, num_steps)

Перемещает Робота в заданном направлении на заданное число шагов
(предполагается, что это возможно - иначе произойдёт ошибка времени выполнения)
"""
function move!(robot, side, num_steps)
    for _ in 1:num_steps
        move!(robot, side)
    end
end

#----------------------------------------------------------------------

"""
inverse(side::HorizonSide)::HorizonSide

Возвращает направление, противоположное заданному
"""
inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))

#----------------------------------------------------------------------

"""
along_wall!(robot, side, d)

Идёт в направлении d вдоль стены, стоящей в направлении side, пока стена
не кончится или путь не преградит рамка. Возвращает число шагов.
"""
function along_wall!(robot, side, d)
    num_steps = 0
    while isborder(robot, side) && !isborder(robot, d)
        move!(robot, d)
        num_steps += 1
    end
    return num_steps
end

#----------------------------------------------------------------------

"""
walk_perimeter!(robot, act)

ДАНО:
    -- Робот в юго-западном углу ограниченного прямоугольного поля
       без внутренних перегородок

РЕЗУЛЬТАТ:
    -- Робот - в юго-западном углу (инвариант);
    -- act(robot) выполнено во всех клетках периметра внешней рамки
       (угловые клетки - по одному разу);
    -- возвращена сумма значений act
"""
function walk_perimeter!(robot, act)
    total = 0
    for side in (Nord, Ost, Sud, West)
        while !isborder(robot, side)
            total += act(robot)
            move!(robot, side)
        end
    end
    return total
end

#----------------------------------------------------------------------

"""
count_marker(robot)

Действие act для подсчёта маркеров: возвращает 1, если в клетке с Роботом
стоит маркер, и 0 - если нет. Обход суммирует эти значения.
"""
count_marker(robot) = Int(ismarker(robot))

# Запуск: julia task09.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task09.sit"), animate = true)
    println(task9!(robot))
end
