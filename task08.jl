# Задача 8. Подсчитать маркеры по периметру внешней рамки
include("lib.jl")

"""
task8!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров по периметру внешней рамки.
"""
function task8!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    counter = MarkerCounter()
    walk_perimeter!(robot, counter)
    #УТВ: маркеры периметра сосчитаны, Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

# Запуск: julia task08.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task08.sit"), animate = true)
    println(task8!(robot))
end
