# Задача 14. Поиск маркера на неограниченном поле (спираль)
include("lib.jl")

function task14!(r)
    n = 1
    side = Nord
    while true
        for _ in 1:2                # два отрезка спирали одной длины
            for _ in 1:n
                ismarker(r) && return
                move!(r, side)
            end
            side = left(side)
        end
        n += 1
    end
end

r = Robot("fields/task14.sit", animate = true)
task14!(r)
