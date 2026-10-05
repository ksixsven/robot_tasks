# Задача 7. Подсчитать маркеры на лучах прямого креста (центр не считается)
include("lib.jl")

"""
task7!(robot)

ДАНО:
    -- Робот находится в произвольной клетке ограниченного прямоугольного поля
       без внутренних перегородок; в некоторых клетках стоят маркеры.

РЕЗУЛЬТАТ:
    -- Робот - в исходном положении (инвариант).
    -- Возвращено число маркеров на лучах креста с центром в клетке с Роботом
       (маркер в самой центральной клетке не считается).
"""
function task7!(robot)
    counter = MarkerCounter()
    walk_kross!(robot, counter)
    #УТВ: Робот - в исходном положении
    return counter.num_markers
end

# Запуск: julia task07.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task07.sit"), animate = true)
    println(task7!(robot))
end
