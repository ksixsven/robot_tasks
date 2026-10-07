using GLMakie
using HorizonSideRobots
import HorizonSideRobots: move!

inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))
left(side::HorizonSide) = HorizonSide(mod(Int(side) + 1, 4))
right(side::HorizonSide) = HorizonSide(mod(Int(side) + 3, 4))

function move_n!(robot, side, num_steps)
    for _ in 1:num_steps
        move!(robot, side)
    end
end

function try_move!(robot, side)::Bool
    num_steps = 0
    while isborder(robot, side) && !isborder(robot, left(side))
        move!(robot, left(side))
        num_steps += 1
    end
    success = false
    if !isborder(robot, side)
        move!(robot, side)
        success = true
        if num_steps > 0
            while isborder(robot, right(side)) && !isborder(robot, side)
                move!(robot, side)
            end
        end
    end
    for _ in 1:num_steps
        if isborder(robot, right(side)) break end
        move!(robot, right(side))
    end
    return success
end

function path_to_angle!(robot, sides_angle::NTuple{2,HorizonSide})
    path = @NamedTuple{side::HorizonSide, num_steps::Int}[]
    moved = true
    while moved
        moved = false
        for side in sides_angle
            n = 0
            while try_move!(robot, side)
                n += 1
            end
            if n > 0
                push!(path, (side = side, num_steps = n))
                moved = true
            end
        end
    end
    return path
end

function return_by_path!(robot, path)
    for i in length(path):-1:1
        for _ in 1:path[i].num_steps
            try_move!(robot, inverse(path[i].side))
        end
    end
    return nothing
end

function count_row_with_borders!(robot, side)
    total = Int(ismarker(robot))
    while try_move!(robot, side)
        total += Int(ismarker(robot))
    end
    return total
end

function count_field_with_borders!(robot)
    path = path_to_angle!(robot, (Sud, West))
    side = Ost
    total = count_row_with_borders!(robot, side)
    while try_move!(robot, Nord)
        side = inverse(side)
        total += count_row_with_borders!(robot, side)
    end
    path_to_angle!(robot, (Sud, West))
    return_by_path!(robot, path)
    return total
end

robot = Robot(animate=true)
println(count_field_with_borders!(robot))