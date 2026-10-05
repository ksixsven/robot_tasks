# Задача 13. Поиск прохода в бесконечной перегородке
include("lib.jl")

"""
task13!(robot, side)

ДАНО:
    -- Робот находится на неограниченном поле, в направлении side от него
       стоит перегородка - бесконечная прямая с единственным проходом
       (в одну клетку) на неизвестном расстоянии.

РЕЗУЛЬТАТ:
    -- Робот прошёл через проход и стоит по другую сторону перегородки
       (в клетке, смежной с проходом в направлении side).

Поиск "челноком": 1 шаг влево, 2 вправо, 4 влево, 8 вправо ... Удвоение длины
захода даёт O(d) шагов до прохода на расстоянии d, а не O(d^2).
"""
function task13!(robot, side)
    d = left(side)                  # направление очередного захода
    num_steps = 1                   # длина очередного захода
    #ИНВАРИАНТ: проход ещё не найден - перегородка в направлении side стоит
    while isborder(robot, side)
        for _ in 1:num_steps
            move!(robot, d)
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2
    end
    #УТВ: Робот напротив прохода
    move!(robot, side)
end

# Запуск: julia task13.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task13.sit"), animate = true)
    task13!(robot, Nord)
end
