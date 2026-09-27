# Задача 8. Подсчитать маркеры по периметру внешней рамки
include("lib.jl")

function task8!(r)
    nw, ns = to_corner!(r)
    c = Counter()
    perimeter!(r, c)
    from_corner!(r, nw, ns)
    return c.k
end

# r = Robot("fields/task08.sit", animate = true)
# println(task8!(r))
