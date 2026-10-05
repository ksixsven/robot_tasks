# Задача 12. Подсчитать маркеры на всём поле (есть перегородки)
include("lib.jl")

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

# Запуск: julia task12.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task12.sit"), animate = true)
    println(task12!(robot))
end
