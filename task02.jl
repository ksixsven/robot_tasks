# Задача 2. Замаркировать периметр внешней рамки
include("lib.jl")

function task2!(r)
    nw, ns = to_corner!(r)      # без перегородок это просто "до упора на запад и на юг"
    perimeter!(r, putmarker!)
    from_corner!(r, nw, ns)
end

r = Robot("fields/task02.sit", animate = true)
task2!(r)
