# Общие функции для всех задач (подключается через include("lib.jl"))
using HorizonSideRobots

# ---------------- Направления ----------------
# Nord=0, West=1, Sud=2, Ost=3: поворот налево - это +1 по модулю 4
inverse(side::HorizonSide) = HorizonSide(mod(Int(side) + 2, 4))
left(side::HorizonSide)    = HorizonSide(mod(Int(side) + 1, 4))
right(side::HorizonSide)   = HorizonSide(mod(Int(side) + 3, 4))

# ---------------- Действия в клетке ----------------
# Все обходы принимают действие f(r), выполняемое в каждой клетке обхода:
#   putmarker!  - поставить маркер
#   Counter()   - посчитать маркеры (результат в поле k)
mutable struct Counter
    k::Int
end
Counter() = Counter(0)
(c::Counter)(r) = (ismarker(r) && (c.k += 1); nothing)

# ---------------- Движение без перегородок ----------------

# Идти до упора, выполняя f после каждого шага (стартовая клетка не обрабатывается).
# Возвращает число шагов.
function line!(r, side, f)
    n = 0
    while !isborder(r, side)
        move!(r, side)
        f(r)
        n += 1
    end
    return n
end

# Двигаться до упора, вернуть число шагов
moves!(r, side) = line!(r, side, Returns(nothing))

# Сделать n шагов
function moves!(r, side, n::Integer)
    for _ in 1:n
        move!(r, side)
    end
end

# ---------------- Ограниченное поле с изолированными перегородками ----------------
# Перегородки не касаются друг друга и внешней рамки, поэтому крайние ряды
# и столбцы поля всегда свободны.

# Идти в направлении d вдоль стены, стоящей в направлении side, пока стена
# не кончится или путь не преградит рамка. Возвращает число шагов.
function along_wall!(r, side, d)
    n = 0
    while isborder(r, side) && !isborder(r, d)
        move!(r, d)
        n += 1
    end
    return n
end

# Робот сдвинут на n шагов в направлении d и стоит сбоку от конца перегородки:
# шагнуть за неё, пройти вдоль прямоугольника и вернуться на исходную линию.
# Возвращает, на сколько клеток робот продвинулся в направлении side.
function pass_wall!(r, side, d, n)
    move!(r, side)
    k = 1
    while isborder(r, inverse(d))       # вдоль прямоугольника, пока он не кончится
        move!(r, side)
        k += 1
    end
    moves!(r, inverse(d), n)            # назад на исходную линию
    return k
end

# Шаг в направлении side с обходом внутренней перегородки.
# Возвращает, на сколько клеток робот продвинулся (при обходе прямоугольника - больше 1),
# или 0, если впереди внешняя рамка (робот остаётся на месте).
function move_bypass!(r, side)
    if !isborder(r, side)
        move!(r, side)
        return 1
    end
    d = left(side)                      # направление обхода
    n = along_wall!(r, side, d)
    if isborder(r, side)                # стена тянется до рамки - это внешняя рамка
        moves!(r, inverse(d), n)
        return 0
    end
    return pass_wall!(r, side, d, n)
end

# Двигаться с обходом перегородок до рамки, вернуть число вызовов move_bypass!
# (при обходе прямоугольника один вызов сдвигает робота больше чем на клетку,
# но на обратном пути по той же линии число вызовов будет тем же)
function moves_bypass!(r, side)
    n = 0
    while move_bypass!(r, side) > 0
        n += 1
    end
    return n
end

function moves_bypass!(r, side, n::Integer)
    for _ in 1:n
        move_bypass!(r, side)
    end
end

# Перейти в юго-западный угол, вернуть (вызовы move_bypass! на запад, шаги на юг).
# Упёршись в стену, идём вдоль неё на юг, как move_bypass!. Если это рамка,
# робот при этом уже спустился в угол - возвращаться обратно незачем.
function to_corner!(r)
    nw = 0
    while true
        if isborder(r, West)
            ns = along_wall!(r, West, Sud)
            isborder(r, West) && return nw, ns
            pass_wall!(r, West, Sud, ns)
        else
            move!(r, West)
        end
        nw += 1
    end
end

# Вернуться из юго-западного угла в исходную клетку
function from_corner!(r, nw, ns)
    moves!(r, Nord, ns)
    moves_bypass!(r, Ost, nw)
end

# Обойти периметр внешней рамки из юго-западного угла (робот возвращается в угол)
function perimeter!(r, f)
    for side in (Nord, Ost, Sud, West)
        while !isborder(r, side)
            f(r)
            move!(r, side)
        end
    end
end

# Змейка по всему полю из юго-западного угла.
# Нижний ряд всегда свободен - по нему узнаём ширину поля, а в остальных рядах
# идём по счётчику столбца x и не тратим шаги на выяснение у края ряда,
# перегородка впереди или рамка.
# Возвращает число подъёмов на север (высота поля минус 1).
function snake!(r, f)
    f(r)
    w = line!(r, Ost, f)                # столбцы x = 0..w
    x, side, up = w, West, 0
    while !isborder(r, Nord)
        move!(r, Nord)
        up += 1
        f(r)
        target = side == Ost ? w : 0
        while x != target
            k = move_bypass!(r, side)
            x += side == Ost ? k : -k
            f(r)
        end
        side = inverse(side)
    end
    return up
end

# Вернуться после змейки в исходную клетку.
# Робот в верхнем ряду; верхний ряд и левый столбец свободны, поэтому
# сразу спускаемся до нужной строки, не заходя в угол.
function back_from_snake!(r, up, nw, ns)
    moves!(r, West)
    moves!(r, Sud, up - ns)
    moves_bypass!(r, Ost, nw)
end

# ---------------- Внутренняя рамка (задачи 5 и 11) ----------------

# Из юго-западного угла найти внутреннюю рамку змейкой.
# Робот останавливается в клетке по диагонали от её левого нижнего угла.
function find_inner!(r)
    side = Ost
    while !isborder(r, Nord)
        while !isborder(r, side) && !isborder(r, Nord)
            move!(r, side)
        end
        isborder(r, Nord) && break
        move!(r, Nord)
        side = inverse(side)
    end
    while isborder(r, Nord)
        move!(r, West)
    end
end

# Клетка у внешней рамки? (стена со стороны left(side) - это внутренняя рамка)
on_frame(r, side) = any(s -> s != left(side) && isborder(r, s), (Nord, West, Sud, Ost))

# Обойти внутреннюю рамку снаружи (вместе с угловыми клетками), выполняя f.
# skip_frame = true - пропускать клетки у внешней рамки (они уже учтены в периметре).
function around_inner!(r, f; skip_frame = false)
    act(side) = (skip_frame && on_frame(r, side)) || f(r)
    for side in (Ost, Nord, West, Sud)
        move!(r, side)
        while isborder(r, left(side))
            act(side)
            move!(r, side)
        end
        act(side)
    end
end
