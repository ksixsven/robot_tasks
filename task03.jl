# Задача 3. Периметр внешней рамки при наличии внутренних перегородок
# (прямоугольники и/или отрезки)
include("lib.jl")

function task3!(r)
    nw, ns = to_corner!(r)      # путь в угол с обходом перегородок
    perimeter!(r, putmarker!)
    from_corner!(r, nw, ns)
end

# r = Robot("fields/task03.sit", animate = true)
# task3!(r)
