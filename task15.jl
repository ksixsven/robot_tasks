# Задача 15. Поиск маркера на неограниченном поле с перегородками
# (отрезки, лучи, прямоугольники) - спираль с обходом перегородок.
# Робот помнит свои координаты pos = [x, y] относительно старта.
include("lib.jl")

# Смещение (dx, dy) для Nord, West, Sud, Ost - в порядке значений HorizonSide
const DELTA = ((0, 1), (-1, 0), (0, -1), (1, 0))
delta(side) = DELTA[Int(side) + 1]

# Шаг с учётом координат
function go!(r, side, pos)
    move!(r, side)
    dx, dy = delta(side)
    pos[1] += dx
    pos[2] += dy
end

# Координата вдоль направления side
function coord(pos, side)
    dx, dy = delta(side)
    return dx * pos[1] + dy * pos[2]
end

# Шаг в направлении side с обходом перегородки.
# Конец перегородки ищется "челноком" в обе стороны (нужно для лучей).
function step_bypass!(r, side, pos)
    if !isborder(r, side)
        go!(r, side, pos)
        return
    end
    d = left(side)
    n = 1
    shift = 0                   # смещение вдоль перегородки (+ налево, - направо)
    while isborder(r, side)
        for _ in 1:n
            go!(r, d, pos)
            shift += d == left(side) ? 1 : -1
            isborder(r, side) || break
        end
        d = inverse(d)
        n *= 2                  # удвоение длины захода, как в задаче 13
    end
    back = shift > 0 ? right(side) : left(side)
    go!(r, side, pos)
    while isborder(r, back)     # для прямоугольника - идём вдоль его стороны
        go!(r, side, pos)
    end
    for _ in 1:abs(shift)       # возвращаемся на исходную линию
        go!(r, back, pos)
    end
end

# Один отрезок спирали: идти в направлении side, пока координата не станет t.
# prev, tprev - направление и цель предыдущего отрезка: если обход
# прямоугольника увёл робота за угол спирали, он возвращается на линию.
# Возвращает true, если маркер найден.
function leg!(r, side, t, prev, tprev, pos)
    while true
        while coord(pos, prev) > tprev && !isborder(r, inverse(prev))
            go!(r, inverse(prev), pos)
            ismarker(r) && return true
        end
        ismarker(r) && return true
        coord(pos, side) >= t && return false
        step_bypass!(r, side, pos)
    end
end

function task15!(r)
    pos = [0, 0]
    prev, tprev = Ost, 0
    t = 1
    while true
        for side in (Nord, West, Sud, Ost)
            leg!(r, side, t, prev, tprev, pos) && return
            prev, tprev = side, t
        end
        t += 1
    end
end

r = Robot(joinpath(@__DIR__, "fields", "task15.sit"), animate = true)
task15!(r)
