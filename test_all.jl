# Случайные тесты всех задач: julia test_all.jl [число_полей_на_задачу]
include("testlib.jl")
for k in 1:15
    include(joinpath(@__DIR__, "task$(lpad(k, 2, '0')).jl"))
end
using Random

const N = isempty(ARGS) ? 300 : parse(Int, ARGS[1])
rng = MersenneTwister(2026)

# ---------- Случайные изолированные перегородки ----------
# Точки решётки, занятые перегородкой: строка y - граница под строкой y, x - граница справа от столбца x
pts(k, a, b) = k == :rect ? Set((y, x) for y in first(a)-1:last(a), x in first(b)-1:last(b)) :
               k == :v    ? Set((y, b) for y in first(a)-1:last(a)) :
                            Set((a, x) for x in first(b)-1:last(b))

randrange(rng, n, L) = (s = rand(rng, 1:n-L+1); s:s+L-1)
function randray(rng, n)                          # отрезок, упирающийся в край поля
    rand(rng, Bool) ? (1:rand(rng, 1:n-1)) : (rand(rng, 2:n):n)
end

# Перегородки не касаются друг друга и рамки (лучи касаются рамки ровно одним концом)
function gen_parts(rng, rows, cols, n; rays = false)
    used = Set{Tuple{Int,Int}}()
    parts = Tuple[]
    onframe(p) = p[1] in (0, rows) || p[2] in (0, cols)
    for _ in 1:200
        length(parts) >= n && break
        k = rand(rng, (:rect, :v, :h))
        isray = rays && k != :rect && rand(rng) < 0.4
        if k == :rect
            a, b = randrange(rng, rows, rand(rng, 1:3)), randrange(rng, cols, rand(rng, 1:3))
        elseif k == :v
            a, b = isray ? randray(rng, rows) : randrange(rng, rows, rand(rng, 1:4)), rand(rng, 1:cols-1)
        else
            a, b = rand(rng, 1:rows-1), isray ? randray(rng, cols) : randrange(rng, cols, rand(rng, 1:4))
        end
        P = pts(k, a, b)
        count(onframe, P) == (isray ? 1 : 0) || continue
        isempty(intersect(P, used)) || continue
        union!(used, P)
        push!(parts, (k, a, b))
    end
    return parts
end
apply!(r, parts) = foreach(((k, a, b),) -> (k == :rect ? rect! : k == :v ? vseg! : hseg!)(r, a, b), parts)
inside_rect(p, parts) = any(((k, a, b),) -> k == :rect && p[1] in a && p[2] in b, parts)
randmarks(rng, rows, cols, p) = [(i, j) for i in 1:rows, j in 1:cols if rand(rng) < p]

# ---------- Прогон и сбор результатов ----------
fails = Dict{Int,Vector{String}}()
total = zeros(Int, 15)
function check!(k, r, desc)
    total[k] += 1
    s = snapshot(r)
    msg = try
        ok, m = verify(k, s, r, runtask(k, CR(r)))
        ok ? nothing : m
    catch e
        "ИСКЛЮЧЕНИЕ: " * sprint(showerror, e)
    end
    isnothing(msg) || push!(get!(fails, k, String[]), "$msg | $desc")
end

for _ in 1:N
    # Поле без перегородок: задачи 1, 2, 4, 7, 8, 10
    rows, cols = rand(rng, 2:10), rand(rng, 2:10)
    st = (rand(rng, 1:rows), rand(rng, 1:cols))
    M = randmarks(rng, rows, cols, 0.3)
    for k in (1, 2, 4, 7, 8, 10)
        check!(k, field(rows, cols; start = st, markers = k in (7, 8, 10) ? M : Cell[]),
               "поле $(rows)x$(cols), старт $st")
    end

    # Перегородки: задачи 3, 6, 9, 12
    rows, cols = rand(rng, 5:14), rand(rng, 5:14)
    parts = gen_parts(rng, rows, cols, rand(rng, 1:6))
    r0 = field(rows, cols); apply!(r0, parts)
    st = rand(rng, collect(reachable(snapshot(r0))))
    M = randmarks(rng, rows, cols, 0.3)
    for k in (3, 6, 9, 12)
        r = field(rows, cols; start = st, markers = k in (9, 12) ? M : Cell[]); apply!(r, parts)
        check!(k, r, "поле $(rows)x$(cols), старт $st, перегородки $parts")
    end

    # Одна внутренняя рамка: задачи 5, 11 (в том числе с зазором в 1 клетку)
    rows, cols = rand(rng, 4:12), rand(rng, 4:12)
    h, w = rand(rng, 1:rows-2), rand(rng, 1:cols-2)
    i1, j1 = rand(rng, 2:rows-h), rand(rng, 2:cols-w)
    rr = ((:rect, i1:i1+h-1, j1:j1+w-1),)
    r0 = field(rows, cols); apply!(r0, rr)
    st = rand(rng, collect(reachable(snapshot(r0))))
    M = randmarks(rng, rows, cols, 0.4)
    for k in (5, 11)
        r = field(rows, cols; start = st, markers = k == 11 ? M : Cell[]); apply!(r, rr)
        check!(k, r, "поле $(rows)x$(cols), рамка $rr, старт $st")
    end

    # Задача 13: бесконечная перегородка с проходом (проход не у края показанной части)
    g, c0 = rand(rng, 2:40), rand(rng, 1:41)
    r = field(5, 41; framed = false, start = (3, c0))
    foreach(j -> j == g || addwall!(r, (3, j), Nord), 1:41)
    check!(13, r, "проход в столбце $g, старт в столбце $c0")

    # Задача 15: спираль среди перегородок и лучей
    parts = filter(p -> !inside_rect((11, 11), (p,)), gen_parts(rng, 21, 21, rand(rng, 1:7); rays = true))
    m = rand(rng, [(i, j) for i in 1:21, j in 1:21 if !inside_rect((i, j), parts)])
    r = field(21, 21; framed = false, start = (11, 11), markers = [m]); apply!(r, parts)
    check!(15, r, "маркер $m, перегородки $parts")
end

# Задача 14: маркер в каждой клетке квадрата 21x21 и несколько далёких
for m in [vec([(i, j) for i in 1:21, j in 1:21]); [(-15, 40), (30, -7), (-20, -20)]]
    check!(14, field(21, 21; framed = false, start = (11, 11), markers = [m]), "маркер в $m")
end

println("="^70)
for k in 1:15
    f = get(fails, k, String[])
    println("Задача $(lpad(k, 2)): проверок $(total[k]), ", isempty(f) ? "OK" : "ОШИБКИ: $(length(f))")
    foreach(m -> println("    - ", first(m, 400)), first(unique(f), 3))
end
