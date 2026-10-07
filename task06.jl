# Задача 6. Замаркировать всё поле при наличии внутренних перегородок

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

"""
task6!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля.
    -- Внутри поля есть изолированные перегородки (прямоугольники и/или отрезки),
       не касающиеся друг друга и внешней рамки; маркеров нет.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Во всех клетках поля, до которых Робот может дойти, стоят маркеры.
"""
function task6!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    snake = walk_snake!(robot, mark_cell!)
    #УТВ: Робот - в верхнем ряду, все доступные клетки замаркированы
    back_from_snake!(robot, snake.num_up, num_west, num_south)
    #УТВ: Робот - в исходном положении
end

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

"""
move_to_frame!(robot, side)

Перемещает Робота в заданном направлении до внешней рамки
"""
function move_to_frame!(robot, side)
    while !isborder(robot, side)
        move!(robot, side)
    end
end

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

"""
walk_snake!(robot, act)

ДАНО:
    -- Робот в юго-западном углу ограниченного поля, у которого нижний ряд
       и левый столбец свободны (внутренние перегородки не касаются рамки)

РЕЗУЛЬТАТ:
    -- act(robot) выполнено во всех клетках, доступных Роботу;
    -- Робот - в верхнем ряду поля;
    -- возвращён именованный кортеж (num_up = число подъёмов на север
       (высота поля минус 1), total = сумма значений act).

Нижний ряд всегда свободен - по нему узнаём ширину поля, а в остальных рядах
идём по счётчику столбца и не тратим шаги на выяснение у края ряда,
перегородка впереди или рамка.
"""
function walk_snake!(robot, act)
    total = act(robot)
    row = walk_to_frame!(robot, Ost, act)
    width = row.num_steps                           # столбцы x = 0..width
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
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

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

# Запуск: julia task06.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task06.sit"), animate = true)
    task6!(robot)
end
