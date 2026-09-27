# Задача 7. Подсчитать маркеры на лучах прямого креста (центр не считается)
include("lib.jl")

function task7!(r)
    c = Counter()
    for side in (Nord, West, Sud, Ost)
        moves!(r, inverse(side), line!(r, side, c))
    end
    return c.k
end

# r = Robot("fields/task07.sit", animate = true)
# println(task7!(r))
