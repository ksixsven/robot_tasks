# Задача 14. Поиск маркера на неограниченном поле (спираль)

using GLMakie
using HorizonSideRobots

"""
task14!(robot)

ДАНО:
    -- Робот находится на неограниченном поле без перегородок;
       где-то на поле стоит маркер.

РЕЗУЛЬТАТ:
    -- Робот стоит в клетке с маркером.

Робот идёт по раскручивающейся спирали: два очередных отрезка имеют
одинаковую длину, затем она увеличивается на 1.
"""
function task14!(robot)
    side = Nord
    num_steps = 1                   # длина двух очередных отрезков спирали
    #ИНВАРИАНТ: маркер не найден в клетках, пройденных по спирали
    while !ismarker(robot)
        for _ in 1:2
            move_until_marker!(robot, side, num_steps)
            side = left(side)
        end
        num_steps += 1
    end
end

"""
move_until_marker!(robot, side, num_steps)

Перемещает Робота в направлении side не более чем на num_steps шагов
и останавливает его, если в очередной клетке (начиная со стартовой) стоит маркер.
"""
function move_until_marker!(robot, side, num_steps)
    for _ in 1:num_steps
        if ismarker(robot) break end
        move!(robot, side)
    end
end

"""
left(side::HorizonSide)::HorizonSide

Возвращает направление налево относительно заданного
"""
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))

# Запуск: julia task14.jl (при запуске из demo.jl и test_all.jl поле создают они сами)
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "fields", "task14.sit"), animate = true)
    task14!(robot)
end
