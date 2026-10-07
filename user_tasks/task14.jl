using GLMakie
using HorizonSideRobots

function find_marker!(robot)
    if ismarker(robot)
        return nothing
    end

    n = 1
    while true
        for _ in 1:n
            if !isborder(robot, Ost) move!(robot, Ost) end
            if ismarker(robot) return nothing end
        end
        for _ in 1:n
            if !isborder(robot, Nord) move!(robot, Nord) end
            if ismarker(robot) return nothing end
        end
        n += 1
        for _ in 1:n
            if !isborder(robot, West) move!(robot, West) end
            if ismarker(robot) return nothing end
        end
        for _ in 1:n
            if !isborder(robot, Sud) move!(robot, Sud) end
            if ismarker(robot) return nothing end
        end
        n += 1
    end
end

robot = Robot(animate=true)
find_marker!(robot)
