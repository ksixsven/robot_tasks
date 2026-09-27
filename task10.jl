# Задача 10. Подсчитать маркеры на всём поле (без перегородок)
include("lib.jl")

function task10!(r)
    nw, ns = to_corner!(r)
    c = Counter()
    up = snake!(r, c)
    back_from_snake!(r, up, nw, ns)
    return c.k
end

# r = Robot("fields/task10.sit", animate = true)
# println(task10!(r))
