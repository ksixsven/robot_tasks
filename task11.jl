# Задача 11. Подсчитать маркеры по периметрам внешней и внутренней рамок
# (клетка, общая для обоих периметров, считается один раз)
include("lib.jl")

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
    counter = MarkerCounter()
    walk_perimeter!(robot, counter)
    #УТВ: маркеры внешнего периметра сосчитаны, Робот - в юго-западном углу
    move_to_inner_frame!(robot)
    walk_around_inner!(robot, counter; skip_frame = true)
    #УТВ: маркеры внутреннего периметра сосчитаны (клетки у внешней рамки пропущены)
    move_to_frame!(robot, Sud)
    move_to_frame!(robot, West)
    #УТВ: Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

# Запуск: julia task11.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task11.sit"), animate = true)
    println(task11!(robot))
end
