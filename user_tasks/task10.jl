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

function count_line_to_border!(robot, side)
    num_steps = 0
    num_markers = 0
    while !isborder(robot, side)
        move!(robot, side)
        num_markers += Int(ismarker(robot))
        num_steps += 1
    end
    return num_steps, num_markers
end

function count_inner_perimetr!(robot, first_side)
    total = 0
    sizes = Int[]
    side = first_side
    for _ in 1:4
        steps, markers = count_line_to_border!(robot, side)
        total += markers
        push!(sizes, steps)
        side = left(side)
    end
    return (total = total, xmax = sizes[1], ymax = sizes[2])
end

function find_inner_bottom!(robot)
    side = Ost
    x, y = 0, 0
    found = isborder(robot, Nord)
    while !found
        while !found && !isborder(robot, side)
            move!(robot, side)
            x += side == Ost ? 1 : -1
            found = isborder(robot, Nord)
        end
        if !found
            move!(robot, Nord)
            y += 1
            found = isborder(robot, Nord)
            side = inverse(side)
        end
    end
    return (x = x, y = y)
end

function move_to_inner_sw_corner!(robot)
    num_steps = 0
    while isborder(robot, Nord)
        move!(robot, West)
        num_steps += 1
    end
    return num_steps
end

# клетки внешнего периметра уже сосчитаны, поэтому здесь они пропускаются
function count_new_marker(robot, x, y, xmax, ymax)
    on_outer = x == 0 || y == 0 || x == xmax || y == ymax
    return Int(ismarker(robot) && !on_outer)
end

function count_inner_frame_from_sw!(robot, x, y, xmax, ymax)
    total = 0
    move!(robot, Ost); x += 1; total += count_new_marker(robot, x, y, xmax, ymax)
    while isborder(robot, Nord)
        move!(robot, Ost); x += 1; total += count_new_marker(robot, x, y, xmax, ymax)
    end
    move!(robot, Nord); y += 1; total += count_new_marker(robot, x, y, xmax, ymax)
    while isborder(robot, West)
        move!(robot, Nord); y += 1; total += count_new_marker(robot, x, y, xmax, ymax)
    end
    move!(robot, West); x -= 1; total += count_new_marker(robot, x, y, xmax, ymax)
    while isborder(robot, Sud)
        move!(robot, West); x -= 1; total += count_new_marker(robot, x, y, xmax, ymax)
    end
    move!(robot, Sud); y -= 1; total += count_new_marker(robot, x, y, xmax, ymax)
    while isborder(robot, Ost)
        move!(robot, Sud); y -= 1; total += count_new_marker(robot, x, y, xmax, ymax)
    end
    return total
end

function count_two_perimeters!(robot)
    path = path_to_angle!(robot, (Sud, West))
    outer = count_inner_perimetr!(robot, Ost)
    pos = find_inner_bottom!(robot)
    dx = move_to_inner_sw_corner!(robot)
    total = outer.total + count_inner_frame_from_sw!(robot, pos.x - dx, pos.y, outer.xmax, outer.ymax)
    move_to_border!(robot, Sud)
    move_to_border!(robot, West)
    return_by_path!(robot, path)
    return total
end

robot = Robot(animate=true)
println(count_two_perimeters!(robot))