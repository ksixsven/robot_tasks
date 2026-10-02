# Задача 6. Замаркировать всё поле при наличии внутренних перегородок
include("lib.jl")

function task6!(r)
    nw, ns = to_corner!(r)
    up = snake!(r, putmarker!)
    back_from_snake!(r, up, nw, ns)
end

r = Robot(joinpath(@__DIR__, "fields", "task06.sit"), animate = true)
task6!(r)
