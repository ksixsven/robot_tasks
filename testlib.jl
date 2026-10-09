# Вспомогательные функции для demo.jl, make_fields.jl и test_all.jl:
# построение полей, ожидаемый результат каждой задачи, текстовая картинка поля.
using HorizonSideRobots

# Признак для файлов задач: не создавать и не запускать робота при include
const TESTING = true

import HorizonSideRobots: move!, isborder, putmarker!, ismarker

const Cell = Tuple{Int,Int}
opp(s::HorizonSide) = HorizonSide(mod(Int(s) + 2, 4))
nbr(p::Cell, s::HorizonSide) = HorizonSideRobots.SituationDatas.adjacent_position(p, s)

const TITLES = [
    "прямой крест",
    "периметр внешней рамки",
    "периметр при внутренних перегородках",
    "всё поле без перегородок",
    "периметры внешней и внутренней рамок",
    "всё поле с перегородками",
    "маркеры на лучах креста",
    "маркеры по периметру",
    "маркеры по периметру (есть перегородки)",
    "маркеры на всём поле",
    "маркеры по периметрам внешней и внутренней рамок",
    "маркеры на всём поле (есть перегородки)",
    "проход в бесконечной перегородке",
    "поиск маркера спиралью",
    "поиск маркера спиралью среди перегородок",
]

# Запуск задачи по номеру (у задачи 13 есть параметр - сторона перегородки)
runtask(k, r) = k == 13 ? task13!(r, Nord) : getfield(Main, Symbol("task$(k)!"))(r)

# ---------- Робот со счётчиком шагов (защита от зацикливания в тестах) ----------
mutable struct CR
    r::Robot
    steps::Int
    limit::Int
end
CR(r::Robot; limit = 300_000) = CR(r, 0, limit)
function move!(c::CR, s::HorizonSide)
    (c.steps += 1) > c.limit && error("превышен лимит шагов ($(c.limit)) - вероятно, зацикливание")
    move!(c.r, s)
end
isborder(c::CR, s::HorizonSide) = isborder(c.r, s)
putmarker!(c::CR) = putmarker!(c.r)
ismarker(c::CR) = ismarker(c.r)

sit(r::Robot) = r.situation
sit(c::CR) = sit(c.r)
pos(r) = sit(r).robot_position
setpos!(r, p) = (sit(r).robot_position = p)
marks(r) = Set{Cell}(sit(r).markers_map)

# ---------- Построение полей ----------
function field(rows, cols; framed = true, start = (rows, 1), markers = Cell[])
    r = Robot(rows, cols)
    sit(r).is_framed = framed
    setpos!(r, start)
    union!(sit(r).markers_map, markers)
    return r
end
addwall!(r, p, side) = push!(sit(r).borders_map[p...], side)
function rect!(r, is, js)                       # прямоугольник из клеток is x js
    for i in is
        addwall!(r, (i, first(js)), West); addwall!(r, (i, last(js)), Ost)
    end
    for j in js
        addwall!(r, (first(is), j), Nord); addwall!(r, (last(is), j), Sud)
    end
end
vseg!(r, is, j) = foreach(i -> addwall!(r, (i, j), Ost), is)    # стенка к востоку от столбца j
hseg!(r, i, js) = foreach(j -> addwall!(r, (i, j), Sud), js)    # стенка к югу от строки i

# ---------- Снимок начальной обстановки и ожидаемый результат ----------
struct Snapshot
    rows::Int
    cols::Int
    start::Cell
    markers::Set{Cell}
    probe::Robot            # копия стен для проверок isborder
end
function snapshot(r)
    s = sit(r)
    rows, cols = Int.(s.frame_size)
    probe = Robot(rows, cols)
    probe.situation.borders_map = deepcopy(s.borders_map)
    probe.situation.is_framed = s.is_framed
    return Snapshot(rows, cols, s.robot_position, marks(r), probe)
end
blocked(probe::Robot, p, side) = (setpos!(probe, p); isborder(probe, side))

inframe(s, p) = 1 <= p[1] <= s.rows && 1 <= p[2] <= s.cols
perimeter(s) = Set{Cell}((i, j) for i in 1:s.rows, j in 1:s.cols if i in (1, s.rows) || j in (1, s.cols))
cross(s) = Set{Cell}(p for p in ((i, j) for i in 1:s.rows, j in 1:s.cols) if p[1] == s.start[1] || p[2] == s.start[2])

function reachable(s::Snapshot)
    seen = Set{Cell}([s.start]); q = [s.start]
    while !isempty(q)
        p = popfirst!(q)
        for side in (Nord, West, Sud, Ost)
            blocked(s.probe, p, side) && continue
            np = nbr(p, side)
            (inframe(s, np) && !(np in seen)) || continue
            push!(seen, np); push!(q, np)
        end
    end
    return seen
end

# Клетки вокруг внутренних прямоугольников (соседи по стороне или углу недоступных клеток)
function ring(s::Snapshot, R = reachable(s))
    inside = Set{Cell}(p for p in ((i, j) for i in 1:s.rows, j in 1:s.cols) if !(p in R))
    return Set{Cell}(p for p in R if any((p[1] + a, p[2] + b) in inside for a in -1:1, b in -1:1))
end

# Клетки, которые задача должна замаркировать / в которых должна считать маркеры
function target(k, s::Snapshot)
    k in (1, 7) && return setdiff(cross(s), [s.start])
    k in (2, 3, 8, 9) && return perimeter(s)
    k in (4, 6, 10, 12) && return reachable(s)
    k in (5, 11) && return union(perimeter(s), ring(s))
    error("нет целевого множества для задачи $k")
end

fmt(ps) = join(sort!(collect(ps)), " ")

# Проверка результата задачи k. Возвращает (ok, пояснение).
function verify(k, s::Snapshot, r, result)
    P = pos(r)
    M = marks(r)
    home = P == s.start ? "робот вернулся в $(s.start)" : "робот НЕ вернулся: $P вместо $(s.start)"
    if k <= 6
        T = target(k, s)
        exp = union(s.markers, T)
        extra, miss = setdiff(M, exp), setdiff(exp, M)
        ok = P == s.start && isempty(extra) && isempty(miss)
        msg = "замаркировано $(length(T)) нужных клеток, $home"
        isempty(miss) || (msg *= "; не хватает: $(fmt(miss))")
        isempty(extra) || (msg *= "; лишние: $(fmt(extra))")
        return ok, msg
    elseif k <= 12
        exp = count(in(target(k, s)), s.markers)
        ok = P == s.start && result == exp && M == s.markers
        msg = "насчитано $result, ожидалось $exp; $home"
        M == s.markers || (msg *= "; маркеры на поле изменились!")
        return ok, msg
    elseif k == 13
        # робот должен оказаться сразу за перегородкой, пройдя через проход
        before = nbr(P, Sud)
        ok = before[1] == s.start[1] && !blocked(s.probe, before, Nord)
        return ok, "проход найден, робот в клетке $P за перегородкой (старт $(s.start))"
    else
        ok = P in s.markers
        return ok, ok ? "робот стоит на маркере $P" : "робот остановился в $P, маркер не найден"
    end
end

# ---------- Текстовая картинка поля ----------
# @ - робот, (@) - робот на маркере, * - маркер, # - недоступная клетка, | и --- - стены
function ascii_field(r; unreachable = Set{Cell}())
    s = snapshot(r)
    M = marks(r)
    P = pos(r)
    hwall(i, j) = blocked(s.probe, (i, j), Sud)           # стена под клеткой (i, j)
    io = IOBuffer()
    println(io, "  .", join((blocked(s.probe, (1, j), Nord) ? "---" : "   ") * "." for j in 1:s.cols))
    for i in 1:s.rows
        line = blocked(s.probe, (i, 1), West) ? "  |" : "   "
        for j in 1:s.cols
            p = (i, j)
            cellstr = p == P ? (p in M ? "(@)" : " @ ") :
                      p in M ? " * " :
                      p in unreachable ? " # " : "   "
            line *= cellstr * (blocked(s.probe, p, Ost) ? "|" : " ")
        end
        println(io, line)
        println(io, "  .", join((hwall(i, j) ? "---" : "   ") * "." for j in 1:s.cols))
    end
    inframe(s, P) || println(io, "  (робот за пределами показанной части поля: $P)")
    return String(take!(io))
end
