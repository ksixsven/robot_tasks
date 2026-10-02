# Задача 1. Замаркировать прямой крест
include("lib.jl")

function task1!(r)
    for side in (Nord, West, Sud, Ost)
        moves!(r, inverse(side), line!(r, side, putmarker!))
    end
    putmarker!(r)               # центр креста
end

r = Robot(joinpath(@__DIR__, "fields", "task01.sit"), animate = true)
task1!(r)
