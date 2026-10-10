# Задача 13. Проход в бесконечной перегородке (поиск "челноком")

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side) = HorizonSide(mod(Int(side) + 2, 4))

left(side) = HorizonSide(mod(Int(side) + 1, 4))

function task13!(robot, side)
    d = left(side)
    num_steps = 1
    while isborder(robot, side)
        for _ in 1:num_steps
            move!(robot, d)
            if !isborder(robot, side) break end
        end
        d = inverse(d)
        num_steps *= 2
    end
    move!(robot, side)
end

# Запуск с анимацией на поле-примере из fields/
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "..", "fields", "task13.sit"), animate = true)
    task13!(robot, Nord)
end
