using GLMakie
using HorizonSideRobots

left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))
right(side::HorizonSide) = HorizonSide(mod(Int(side) + 3, 4))

function find_passage!(robot, wall_side::HorizonSide)
    if !isborder(robot, wall_side)
        move!(robot, wall_side)
        return nothing
    end

    dir1 = left(wall_side)
    dir2 = right(wall_side)
    n = 1

    while true
        for _ in 1:n
            if isborder(robot, dir1) break end
            move!(robot, dir1)
            if !isborder(robot, wall_side)
                move!(robot, wall_side)
                return nothing
            end
        end
        n += 1
        for _ in 1:n
            if isborder(robot, dir2) break end
            move!(robot, dir2)
            if !isborder(robot, wall_side)
                move!(robot, wall_side)
                return nothing
            end
        end
        n += 1
    end
end

robot = Robot(animate=true)
find_passage!(robot, Nord)
