# Создаёт поля-примеры fields/taskNN.sit для demo.jl
# Запуск: julia make_fields.jl
include("testlib.jl")

# Перегородки для задач 3, 6, 9, 12: два прямоугольника и два отрезка
function partitions!(r)
    rect!(r, 3:4, 3:5)
    rect!(r, 7:8, 2:3)
    vseg!(r, 6:8, 8)
    hseg!(r, 2, 8:10)
end

fields = Dict{Int,Robot}()

fields[1]  = field(8, 10; start = (5, 4))
fields[2]  = field(8, 10; start = (4, 6))
fields[3]  = field(10, 12; start = (4, 7));  partitions!(fields[3])
fields[4]  = field(7, 9; start = (3, 5))
fields[5]  = field(10, 12; start = (8, 10)); rect!(fields[5], 4:6, 5:8)
fields[6]  = field(10, 12; start = (9, 6));  partitions!(fields[6])

# 4 маркера на лучах, 1 в центре (не считается), 3 вне креста -> ответ 4
fields[7]  = field(8, 10; start = (4, 5),
                   markers = [(4, 1), (4, 8), (1, 5), (7, 5), (4, 5), (2, 2), (6, 8), (8, 10)])
# 5 маркеров на периметре, 2 внутри -> ответ 5
fields[8]  = field(8, 10; start = (5, 5),
                   markers = [(1, 1), (1, 6), (8, 10), (5, 1), (3, 10), (3, 3), (6, 6)])
# 4 на периметре, 2 внутри -> ответ 4
fields[9]  = field(10, 12; start = (4, 7),
                   markers = [(1, 3), (10, 12), (6, 1), (10, 5), (5, 6), (9, 9)])
partitions!(fields[9])
# 9 маркеров -> ответ 9
fields[10] = field(7, 9; start = (4, 4),
                   markers = [(1, 1), (1, 9), (2, 5), (3, 3), (4, 4), (5, 8), (6, 2), (7, 7), (7, 9)])
# Внутренняя рамка в одной клетке от верхней стороны внешней: клетки (1, 3..8) общие.
# (1,5), (1,3) - общие; (5,8), (3,8) - у внутренней; (9,1) - у внешней; (6,6) - нигде -> ответ 5
fields[11] = field(9, 11; start = (7, 9),
                   markers = [(1, 5), (1, 3), (5, 8), (3, 8), (9, 1), (6, 6)])
rect!(fields[11], 2:4, 4:7)
# 4 доступных маркера + 1 внутри прямоугольника (робот до него не доберётся) -> ответ 4
fields[12] = field(10, 12; start = (9, 6),
                   markers = [(2, 2), (5, 9), (10, 12), (7, 9), (3, 4)])
partitions!(fields[12])

# Бесконечная горизонтальная перегородка севернее строки 3, проход в столбце 15
fields[13] = field(5, 21; framed = false, start = (3, 9))
foreach(j -> j == 15 || addwall!(fields[13], (3, j), Nord), 1:21)

fields[14] = field(11, 11; framed = false, start = (6, 6), markers = [(4, 9)])

# Прямоугольник, отрезок и луч (уходит на запад в бесконечность)
fields[15] = field(13, 13; framed = false, start = (7, 7), markers = [(2, 5)])
rect!(fields[15], 3:4, 6:8)
vseg!(fields[15], 6:8, 9)
hseg!(fields[15], 9, 1:6)

dir = joinpath(@__DIR__, "fields")
mkpath(dir)
for k in sort(collect(keys(fields)))
    r = fields[k]
    file = joinpath(dir, "task$(lpad(k, 2, '0')).sit")
    save_sit(r, file)
    println("создан ", file)
end
