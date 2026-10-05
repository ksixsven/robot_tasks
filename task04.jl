# Задача 4. Замаркировать всё поле (без перегородок)
include("lib.jl")

"""
task4!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок и маркеров.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Во всех клетках поля стоят маркеры.
"""
function task4!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    num_up = walk_snake!(robot, putmarker!)
    #УТВ: Робот - в верхнем ряду, все клетки замаркированы
    back_from_snake!(robot, num_up, num_west, num_south)
    #УТВ: Робот - в исходном положении
end

# Запуск: julia task04.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task04.sit"), animate = true)
    task4!(robot)
end
