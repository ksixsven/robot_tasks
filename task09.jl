# Задача 9. Подсчитать маркеры по периметру внешней рамки (есть перегородки)
include("lib.jl")

function task9!(r)
    nw, ns = to_corner!(r)
    c = Counter()
    perimeter!(r, c)
    from_corner!(r, nw, ns)
    return c.k
end

r = Robot("fields/task09.sit", animate = true)
println(task9!(r))
