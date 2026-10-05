# Задача 5. Замаркировать периметры внешней и внутренней рамок
include("lib.jl")

"""
task5!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля,
       внутри которого есть одна прямоугольная перегородка (внутренняя рамка),
       не касающаяся внешней рамки; маркеров нет.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Маркеры расставлены по периметру внешней рамки и по периметру
       (снаружи) внутренней рамки.
"""
function task5!(robot)
    num_west, num_south = to_corner!(robot)
    #УТВ: Робот - в юго-западном углу
    walk_perimeter!(robot, putmarker!)
    #УТВ: внешний периметр замаркирован, Робот - в юго-западном углу
    move_to_inner_frame!(robot)
    #УТВ: Робот - рядом с углом внутренней рамки
    walk_around_inner!(robot, putmarker!)
    #УТВ: внутренняя рамка замаркирована
    move_to_frame!(robot, Sud)      # назад в юго-западный угол
    move_to_frame!(robot, West)
    #УТВ: Робот - в юго-западном углу
    from_corner!(robot, num_west, num_south)
    #УТВ: Робот - в исходном положении
end

# Запуск: julia task05.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task05.sit"), animate = true)
    task5!(robot)
end
