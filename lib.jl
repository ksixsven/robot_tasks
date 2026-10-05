# Библиотека функций для задач с Роботом (подключается через include("lib.jl")).
#
# Соглашения (лекции 2 и 3):
#   -- у каждой функции есть контракт ДАНО / РЕЗУЛЬТАТ;
#   -- имя функции, меняющей состояние Робота, оканчивается на "!";
#   -- типы параметров указываются только там, где они используются в теле функции;
#   -- без глобальных изменяемых переменных: данные передаются через параметры
#      и возвращаются как результат.
using HorizonSideRobots

import HorizonSideRobots: move!

#--------------------------------------------------------------------------
# Направления
#--------------------------------------------------------------------------

# Nord = 0, West = 1, Sud = 2, Ost = 3: поворот налево - это +1 по модулю 4

"""
inverse(side::HorizonSide)::HorizonSide

Возвращает направление, противоположное заданному
"""
inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))

"""
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

"""
right(side::HorizonSide)::HorizonSide

Возвращает направление направо относительно заданного
"""
right(side::HorizonSide) = HorizonSide(mod(Int(side) + 3, 4))

#--------------------------------------------------------------------------
# Действия в клетке (параметр act обходов)
#--------------------------------------------------------------------------

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

#--------------------------------------------------------------------------
# Движение по полю без перегородок
#--------------------------------------------------------------------------

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
move_to_frame!(robot, side)

Перемещает Робота в заданном направлении до внешней рамки
"""
function move_to_frame!(robot, side)
    while !isborder(robot, side)
        move!(robot, side)
    end
end

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

"""
nsteps_putmarkers_to_border!(robot, side)

ДАНО:
    -- Робот в некоторой клетке поля

РЕЗУЛЬТАТ:
    -- Робот переместился по прямой до упора в направлении side;
    -- во всех пройденных клетках, кроме начальной, поставлен маркер;
    -- возвращено число сделанных шагов
"""
nsteps_putmarkers_to_border!(robot, side) = nsteps_move_to_frame!(robot, side, putmarker!)

#--------------------------------------------------------------------------
# Обходы поля без перегородок: в каждой клетке выполняется act(robot)
#--------------------------------------------------------------------------

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

"""
walk_perimeter!(robot, act)

ДАНО:
    -- Робот в юго-западном углу ограниченного прямоугольного поля
       без внутренних перегородок

РЕЗУЛЬТАТ:
    -- Робот - в юго-западном углу (инвариант);
    -- act(robot) выполнено во всех клетках периметра внешней рамки
       (угловые клетки - по одному разу)
"""
function walk_perimeter!(robot, act)
    for side in (Nord, Ost, Sud, West)
        while !isborder(robot, side)
            act(robot)
            move!(robot, side)
        end
    end
end

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

#--------------------------------------------------------------------------
# Поле с изолированными перегородками
#--------------------------------------------------------------------------
# Перегородки не касаются друг друга и внешней рамки, поэтому крайние ряды
# и столбцы поля всегда свободны.

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
nsteps_move_bypass_to_frame!(robot, side)

Двигает Робота с обходом перегородок до внешней рамки в направлении side;
возвращает число вызовов move_bypass!. При обходе прямоугольника один вызов
сдвигает Робота больше чем на клетку, но на обратном пути по той же линии
число вызовов будет тем же.
"""
function nsteps_move_bypass_to_frame!(robot, side)
    num_steps = 0
    while move_bypass!(robot, side) > 0
        num_steps += 1
    end
    return num_steps
end

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

#--------------------------------------------------------------------------
# Внутренняя рамка (задачи 5 и 11)
#--------------------------------------------------------------------------

"""
move_to_inner_frame!(robot)

ДАНО:
    -- Робот в юго-западном углу поля, в котором есть одна внутренняя
       прямоугольная перегородка (рамка)

РЕЗУЛЬТАТ:
    -- Робот в клетке по диагонали от левого нижнего угла внутренней рамки
       (стена рамки - над клеткой Робота, а слева от неё - клетка, граничащая с рамкой)

Ищем рамку змейкой: идём по ряду, пока не упрёмся в стену, затем вверх и обратно.
"""
function move_to_inner_frame!(robot)
    side = Ost
    while !isborder(robot, Nord)
        if isborder(robot, side)
            move!(robot, Nord)
            side = inverse(side)
        else
            move!(robot, side)
        end
    end
    #УТВ: над Роботом стена внутренней рамки
    while isborder(robot, Nord)
        move!(robot, West)
    end
end

"""
on_frame(robot, side)

Клетка с Роботом у внешней рамки? (стена со стороны left(side) - это внутренняя рамка)
"""
on_frame(robot, side) = any(s -> s != left(side) && isborder(robot, s), (Nord, West, Sud, Ost))

"""
walk_around_inner!(robot, act; skip_frame = false)

ДАНО:
    -- Робот в клетке, найденной move_to_inner_frame!

РЕЗУЛЬТАТ:
    -- act(robot) выполнено во всех клетках вокруг внутренней рамки снаружи
       (вместе с угловыми клетками);
    -- при skip_frame = true клетки у внешней рамки пропускаются
       (они уже учтены при обходе периметра).
"""
function walk_around_inner!(robot, act; skip_frame = false)
    act_here(side) = (skip_frame && on_frame(robot, side)) || act(robot)
    for side in (Ost, Nord, West, Sud)
        move!(robot, side)
        while isborder(robot, left(side))
            act_here(side)
            move!(robot, side)
        end
        act_here(side)
    end
end
