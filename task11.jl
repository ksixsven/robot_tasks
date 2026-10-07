# Задача 11. Подсчитать маркеры по периметрам внешней и внутренней рамок
# (клетка, общая для обоих периметров, считается один раз)

using HorizonSideRobots
import HorizonSideRobots: move!

"""
task11!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля,
       внутри которого есть одна прямоугольная перегородка (внутренняя рамка),
       не касающаяся внешней рамки; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров по периметрам внешней и внутренней рамок
       (снаружи); клетка, общая для обоих периметров, считается один раз.
"""
function task11!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    num_markers = walk_perimeter!(robot, count_marker)
    #УТВ: маркеры внешнего периметра сосчитаны, Робот - в юго-западном углу
    move_to_inner_frame!(robot)
    num_markers += walk_around_inner!(robot, count_marker; skip_frame = true)
    #УТВ: маркеры внутреннего периметра сосчитаны (клетки у внешней рамки пропущены)
    move_to_frame!(robot, Sud)
    move_to_frame!(robot, West)
    #УТВ: Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return num_markers
end

#----------------------------------------------------------------------

"""
walk_around_inner!(robot, act; skip_frame = false)

ДАНО:
    -- Робот в клетке, найденной move_to_inner_frame!

РЕЗУЛЬТАТ:
    -- act(robot) выполнено во всех клетках вокруг внутренней рамки снаружи
       (вместе с угловыми клетками);
    -- при skip_frame = true клетки у внешней рамки пропускаются
       (они уже учтены при обходе периметра);
    -- возвращена сумма значений act.
"""
function walk_around_inner!(robot, act; skip_frame = false)
    act_here(side) = (skip_frame && on_frame(robot, side)) ? 0 : act(robot)
    total = 0
    for side in (Ost, Nord, West, Sud)
        move!(robot, side)
        while isborder(robot, left(side))
            total += act_here(side)
            move!(robot, side)
        end
        total += act_here(side)
    end
    return total
end

#----------------------------------------------------------------------

"""
on_frame(robot, side)

Клетка с Роботом у внешней рамки? (стена со стороны left(side) - это внутренняя рамка)
"""
on_frame(robot, side) = any(s -> s != left(side) && isborder(robot, s), (Nord, West, Sud, Ost))

#----------------------------------------------------------------------

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
count_marker(robot)

Действие act для подсчёта маркеров: возвращает 1, если в клетке с Роботом
стоит маркер, и 0 - если нет. Обход суммирует эти значения.
"""
count_marker(robot) = Int(ismarker(robot))

# Запуск: julia task11.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task11.sit"), animate = true)
    println(task11!(robot))
end
