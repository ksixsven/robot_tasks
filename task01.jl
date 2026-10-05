# Задача 1. Замаркировать прямой крест
include("lib.jl")

"""
task1!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок и маркеров.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- На поле расставлены маркеры в форме прямого креста вплоть до внешней рамки,
       с центром в клетке с роботом.
"""
function task1!(robot)
    walk_kross!(robot, putmarker!)
    putmarker!(robot)   # центр креста
end

# Запуск: julia task01.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task01.sit"), animate = true)
    task1!(robot)
end
