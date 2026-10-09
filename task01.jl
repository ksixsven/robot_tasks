# Задача 1. Замаркировать прямой крест

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

"""
task1!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок и маркеров.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- На поле расставлены маркеры в форме прямого креста вплоть до внешней рамки,
       с центром в клетке с роботом (в самой клетке с роботом маркера нет).
"""
function task1!(robot)
    walk_kross!(robot, mark_cell!)
end

"""
walk_kross!(robot, act)

ДАНО:
    -- Робот в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант);
    -- act(robot) выполнено во всех клетках лучей креста с центром
       в клетке с роботом (сама центральная клетка не обрабатывается);
    -- возвращена сумма значений act
"""
function walk_kross!(robot, act)
    total = 0
    for side in (Nord, West, Sud, Ost)
        ray = walk_to_frame!(robot, side, act)
        move!(robot, inverse(side), ray.num_steps)
        total += ray.total
    end
    return total
end

"""
walk_to_frame!(robot, side, act)

Перемещает Робота в заданном направлении до внешней рамки, выполняя act(robot)
после каждого шага (в стартовой клетке act не выполняется).
Возвращает именованный кортеж (num_steps = число шагов, total = сумма значений act).
Примеры act: mark_cell!, count_marker.
"""
function walk_to_frame!(robot, side, act)
    num_steps, total = 0, 0
    while !isborder(robot, side)
        move!(robot, side)
        total += act(robot)
        num_steps += 1
    end
    return (num_steps = num_steps, total = total)
end

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

"""
inverse(side::HorizonSide)::HorizonSide

Возвращает направление, противоположное заданному
"""
inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))

"""
mark_cell!(robot)

Действие act для расстановки маркеров: ставит маркер в клетке с Роботом.
Возвращает 0 - клетка не даёт вклада в число, возвращаемое обходом.
"""
function mark_cell!(robot)
    putmarker!(robot)
    return 0
end

# Запуск: julia task01.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task01.sit"), animate = true)
    task1!(robot)
end
