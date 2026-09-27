# Задача 12. Подсчитать маркеры на всём поле (есть перегородки)
include("lib.jl")

function task12!(r)
    nw, ns = to_corner!(r)
    c = Counter()
    up = snake!(r, c)
    back_from_snake!(r, up, nw, ns)
    return c.k
end

# r = Robot("fields/task12.sit", animate = true)
# println(task12!(r))
