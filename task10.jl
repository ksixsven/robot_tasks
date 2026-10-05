# Задача 10. Подсчитать маркеры на всём поле (без перегородок)
include("lib.jl")

"""
task10!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число клеток поля, в которых стоят маркеры.
"""
function task10!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    counter = MarkerCounter()
    num_up = walk_snake!(robot, counter)
    #УТВ: Робот - в верхнем ряду, все клетки обойдены
    back_from_snake!(robot, num_up, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

# Запуск: julia task10.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task10.sit"), animate = true)
    println(task10!(robot))
end
