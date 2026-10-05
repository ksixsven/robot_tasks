# Задача 9. Подсчитать маркеры по периметру внешней рамки (есть перегородки)
include("lib.jl")

"""
task9!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля.
    -- Внутри поля есть изолированные перегородки, не касающиеся друг друга
       и внешней рамки; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров по периметру внешней рамки.
"""
function task9!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    counter = MarkerCounter()
    walk_perimeter!(robot, counter)
    #УТВ: маркеры периметра сосчитаны, Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

# Запуск: julia task09.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task09.sit"), animate = true)
    println(task9!(robot))
end
