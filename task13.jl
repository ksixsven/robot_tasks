# Задача 13. Поиск прохода в бесконечной перегородке
# side - сторона, с которой находится перегородка
include("lib.jl")

function task13!(r, side)
    d = left(side)
    n = 1
    while isborder(r, side)
        for _ in 1:n                # "челнок": 1 влево, 2 вправо, 4 влево, 8 вправо ...
            move!(r, d)
            isborder(r, side) || break
        end
        d = inverse(d)
        n *= 2                      # удвоение: до прохода на расстоянии d - O(d) шагов, а не O(d^2)
    end
    move!(r, side)                  # проходим через проход
end

# r = Robot("fields/task13.sit", animate = true)
# task13!(r, Nord)
