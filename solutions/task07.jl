# Задача 7. Число маркеров на лучах креста

using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side) = HorizonSide(mod(Int(side) + 2, 4))

function move!(robot, side, num_steps)
    for _ in 1:num_steps
        move!(robot, side)
    end
end

count_marker(robot) = Int(ismarker(robot))

# Идёт в сторону side до рамки, выполняя act после каждого шага.
function walk_to_frame!(robot, side, act)
    num_steps, total = 0, 0
    while !isborder(robot, side)
        move!(robot, side)
        total += act(robot)
        num_steps += 1
    end
    return (num_steps = num_steps, total = total)
end

# Обход лучей креста с возвратом в центр; центр не обрабатывается.
function walk_kross!(robot, act)
    total = 0
    for side in (Nord, West, Sud, Ost)
        ray = walk_to_frame!(robot, side, act)
        move!(robot, inverse(side), ray.num_steps)
        total += ray.total
    end
    return total
end

function task7!(robot)
    return walk_kross!(robot, count_marker)
end

# Запуск с анимацией на поле-примере из fields/
if !isdefined(Main, :TESTING)
    robot = Robot(joinpath(@__DIR__, "..", "fields", "task07.sit"), animate = true)
    println(task7!(robot))
end
