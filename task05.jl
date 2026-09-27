# Задача 5. Замаркировать периметры внешней и внутренней рамок
include("lib.jl")

function task5!(r)
    nw, ns = to_corner!(r)
    perimeter!(r, putmarker!)
    find_inner!(r)
    around_inner!(r, putmarker!)
    moves!(r, Sud)              # назад в юго-западный угол
    moves!(r, West)
    from_corner!(r, nw, ns)
end

# r = Robot("fields/task05.sit", animate = true)
# task5!(r)
