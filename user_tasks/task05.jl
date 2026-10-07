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

function move_to_border!(robot, side)
    while !isborder(robot, side)
        move!(robot, side)
    end
    return nothing
end

function nsteps_putmarkers_to_border!(robot, side)
    num_steps = 0
    while !isborder(robot, side)
        move!(robot, side)
        putmarker!(robot)
        num_steps += 1
    end
    return num_steps
end

function mark_inner_perimetr!(robot, first_side)
    side = first_side
    for _ in 1:4
        nsteps_putmarkers_to_border!(robot, side)
        side = left(side)
    end
    return nothing
end

function find_inner_bottom!(robot)
    side = Ost
    found = isborder(robot, Nord)
    while !found
        while !found && !isborder(robot, side)
            move!(robot, side)
            found = isborder(robot, Nord)
        end
        if !found
            move!(robot, Nord)
            found = isborder(robot, Nord)
            side = inverse(side)
        end
    end
    return nothing
end

function move_to_inner_sw_corner!(robot)
    while isborder(robot, Nord)
        move!(robot, West)
    end
    return nothing
end

function mark_inner_frame_from_sw!(robot)
    move!(robot, Ost); putmarker!(robot)
    while isborder(robot, Nord)
        move!(robot, Ost); putmarker!(robot)
    end
    move!(robot, Nord); putmarker!(robot)
    while isborder(robot, West)
        move!(robot, Nord); putmarker!(robot)
    end
    move!(robot, West); putmarker!(robot)
    while isborder(robot, Sud)
        move!(robot, West); putmarker!(robot)
    end
    move!(robot, Sud); putmarker!(robot)
    while isborder(robot, Ost)
        move!(robot, Sud); putmarker!(robot)
    end
    return nothing
end

function mark_two_perimeters!(robot)
    path = path_to_angle!(robot, (Sud, West))
    find_inner_bottom!(robot)
    move_to_inner_sw_corner!(robot)
    mark_inner_frame_from_sw!(robot)
    move_to_border!(robot, Sud)
    move_to_border!(robot, West)
    mark_inner_perimetr!(robot, Ost)
    return_by_path!(robot, path)
    return nothing
end

robot = Robot(animate=true)
mark_two_perimeters!(robot)
