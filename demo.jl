# Демонстрация задач на полях-примерах из папки fields/
#
#   julia demo.jl              - все задачи: картинка поля до/после и проверка результата
#   julia demo.jl 5 11         - только задачи 5 и 11
#   julia demo.jl 5 anim       - задача 5 с анимацией в окне (нужен пакет GLMakie)
#   julia demo.jl all anim     - все задачи с анимацией
#
# Для каждой задачи печатается OK или ОШИБКА с пояснением.
const ANIM = "anim" in ARGS
ANIM && @eval using GLMakie

include("testlib.jl")
for k in 1:15
    include(joinpath(@__DIR__, "task$(lpad(k, 2, '0')).jl"))
end

nums = [parse(Int, a) for a in ARGS if all(isdigit, a)]
isempty(nums) && (nums = collect(1:15))

passed = 0
for k in nums
    file = joinpath(@__DIR__, "fields", "task$(lpad(k, 2, '0')).sit")
    println("\n", "="^70, "\nЗадача $k: $(TITLES[k])   [fields/$(basename(file))]")
    r = Robot(file)
    s = snapshot(r)
    if ANIM
        # окно только для просмотра: Robot(file; animate = true) открыло бы поле
        # в режиме редактирования, где случайный клик меняет стены и маркеры
        r.animate = true
        HorizonSideRobots.SituationDatas.draw(sit(r))
    end
    unreachable = s.probe.situation.is_framed ?
        setdiff(Set{Cell}((i, j) for i in 1:s.rows, j in 1:s.cols), reachable(s)) : Set{Cell}()
    ANIM || print("До:\n", ascii_field(r; unreachable))
    if ANIM
        print("Окно с полем открыто. Enter - запустить робота... ")
        readline()
    end

    result = runtask(k, r)

    ANIM || print("После:\n", ascii_field(r; unreachable))
    k in 7:12 && println("Результат: ", result)
    ok, msg = verify(k, s, r, result)
    global passed += ok
    println(ok ? "OK" : "ОШИБКА", ": ", msg)
    if ANIM && k != last(nums)
        print("Enter - следующая задача... ")
        readline()
    end
end
println("\n", "="^70, "\nИтого: $passed из $(length(nums)) задач выполнены верно")
ANIM && (print("Enter - выход... "); readline())
