# Задача 7. Подсчитать маркеры на лучах прямого креста (центр не считается)

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
    counter = MarkerCounter()
    walk_kross!(robot, counter)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

#----------------------------------------------------------------------

"""
walk_kross!(robot, act)

ДАНО:
    -- Робот в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант);
    -- act(robot) выполнено во всех клетках лучей креста с центром
       в клетке с роботом (сама центральная клетка не обрабатывается)
"""
function walk_kross!(robot, act)
    for side in (Nord, West, Sud, Ost)
        num_steps = nsteps_move_to_frame!(robot, side, act)
        move!(robot, inverse(side), num_steps)
    end
end

#----------------------------------------------------------------------

"""
nsteps_move_to_frame!(robot, side)

Перемещает Робота в заданном направлении до внешней рамки
и возвращает число сделанных шагов
"""
function nsteps_move_to_frame!(robot, side)
    num_steps = 0
    while !isborder(robot, side)
        move!(robot, side)
        num_steps += 1
    end
    return num_steps
end

"""
nsteps_move_to_frame!(robot, side, act)

Перемещает Робота в заданном направлении до внешней рамки, выполняя act(robot)
после каждого шага (в стартовой клетке act не выполняется);
возвращает число сделанных шагов.
Примеры act: putmarker!, MarkerCounter().
"""
function nsteps_move_to_frame!(robot, side, act)
    num_steps = 0
    while !isborder(robot, side)
        move!(robot, side)
        act(robot)
        num_steps += 1
    end
    return num_steps
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
MarkerCounter()

Счётчик маркеров. Объект вызывается как функция act(robot): если в клетке
с роботом стоит маркер, число num_markers увеличивается на 1.
Передаётся в обходы явным параметром (глобальных переменных нет).
"""
mutable struct MarkerCounter
    num_markers::Int
end

MarkerCounter() = MarkerCounter(0)

function (counter::MarkerCounter)(robot)
    if ismarker(robot)
        counter.num_markers += 1
    end
end

# Запуск: julia task07.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task07.sit"), animate = true)
    println(task7!(robot))
end
