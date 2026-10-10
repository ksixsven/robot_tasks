# Задача 14. Маркер на неограниченном поле (спираль)

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

left(side) = HorizonSide(mod(Int(side) + 1, 4))

function move_until_marker!(robot, side, num_steps)
    for _ in 1:num_steps
        if ismarker(robot) break end
        move!(robot, side)
    end
end

function task14!(robot)
    side = Nord
    num_steps = 1
    while !ismarker(robot)
        for _ in 1:2
            move_until_marker!(robot, side, num_steps)
            side = left(side)
        end
        num_steps += 1
    end
end

# Запуск с анимацией на поле-примере из fields/
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "..", "fields", "task14.sit"), animate = true)
    task14!(robot)
end
