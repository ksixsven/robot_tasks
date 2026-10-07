# Задача 12. Подсчитать маркеры на всём поле (есть перегородки)

using HorizonSideRobots
import HorizonSideRobots: move!

"""
task12!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля.
    -- Внутри поля есть изолированные перегородки, не касающиеся друг друга
       и внешней рамки; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число клеток, в которых стоят маркеры (достижимых для Робота).
"""
function task12!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    counter = MarkerCounter()
    num_up = walk_snake!(robot, counter)
    #УТВ: Робот - в верхнем ряду, все доступные клетки обойдены
    back_from_snake!(robot, num_up, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

#----------------------------------------------------------------------

"""
back_from_snake!(robot, num_up, num_west, num_south)

ДАНО:
    -- Робот в верхнем ряду после walk_snake!; num_up - результат walk_snake!,
       (num_west, num_south) - результат to_corner!

РЕЗУЛЬТАТ:
    -- Робот в исходной клетке

Верхний ряд и левый столбец свободны, поэтому сразу спускаемся
до нужной строки, не заходя в угол.
"""
function back_from_snake!(robot, num_up, num_west, num_south)
    move_to_frame!(robot, West)
    move!(robot, Sud, num_up - num_south)
    move_bypass!(robot, Ost, num_west)
end

#----------------------------------------------------------------------

"""
move_to_frame!(robot, side)

Перемещает Робота в заданном направлении до внешней рамки
"""
function move_to_frame!(robot, side)
    while !isborder(robot, side)
        move!(robot, side)
    end
end

#----------------------------------------------------------------------

"""
to_corner!(robot)

ДАНО:
    -- Робот в произвольной клетке ограниченного поля (перегородки изолированы)

РЕЗУЛЬТАТ:
    -- Робот в юго-западном углу;
    -- возвращён кортеж (число вызовов move_bypass! на запад, число шагов на юг) -
       по нему путь назад находит from_corner!.

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
    return num_west, num_south
end

#----------------------------------------------------------------------

"""
walk_snake!(robot, act)

ДАНО:
    -- Робот в юго-западном углу ограниченного поля, у которого нижний ряд
       и левый столбец свободны (внутренние перегородки не касаются рамки)

РЕЗУЛЬТАТ:
    -- act(robot) выполнено во всех клетках, доступных Роботу;
    -- Робот - в верхнем ряду поля;
    -- возвращено число подъёмов на север (высота поля минус 1).

Нижний ряд всегда свободен - по нему узнаём ширину поля, а в остальных рядах
идём по счётчику столбца и не тратим шаги на выяснение у края ряда,
перегородка впереди или рамка.
"""
function walk_snake!(robot, act)
    act(robot)
    width = nsteps_move_to_frame!(robot, Ost, act)   # столбцы x = 0..width
    x, side, num_up = width, West, 0
    while !isborder(robot, Nord)
        move!(robot, Nord)
        num_up += 1
        act(robot)
        target = side == Ost ? width : 0
        while x != target
            k = move_bypass!(robot, side)
            x += side == Ost ? k : -k
            act(robot)
        end
        side = inverse(side)
    end
    return num_up
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
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

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

# Запуск: julia task12.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task12.sit"), animate = true)
    println(task12!(robot))
end
