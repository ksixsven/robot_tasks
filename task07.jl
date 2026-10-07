# Задача 7. Подсчитать маркеры на лучах прямого креста (центр не считается)

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

"""
task7!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров на лучах креста с центром в клетке с Роботом
       (маркер в самой центральной клетке не считается).
"""
function task7!(robot)
    num_markers = walk_kross!(robot, count_marker)
    #УТВ: Робот - в исходном положении
    return num_markers
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
count_marker(robot)

Действие act для подсчёта маркеров: возвращает 1, если в клетке с Роботом
стоит маркер, и 0 - если нет. Обход суммирует эти значения.
"""
count_marker(robot) = Int(ismarker(robot))

# Запуск: julia task07.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task07.sit"), animate = true)
    println(task7!(robot))
end
