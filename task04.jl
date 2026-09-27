# Задача 4. Замаркировать всё поле (без перегородок)
include("lib.jl")

function task4!(r)
    nw, ns = to_corner!(r)
    up = snake!(r, putmarker!)
    back_from_snake!(r, up, nw, ns)
end

r = Robot("fields/task04.sit", animate = true)
task4!(r)
