# Задача 11. Подсчитать маркеры по периметрам внешней и внутренней рамок
# (клетка, общая для обоих периметров, считается один раз)
include("lib.jl")

function task11!(r)
    nw, ns = to_corner!(r)
    c = Counter()
    perimeter!(r, c)
    find_inner!(r)
    around_inner!(r, c; skip_frame = true)
    moves!(r, Sud)
    moves!(r, West)
    from_corner!(r, nw, ns)
    return c.k
end

r = Robot(joinpath(@__DIR__, "fields", "task11.sit"), animate = true)
println(task11!(r))
