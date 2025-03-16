using Pkg
Pkg.activate(".")
Pkg.instantiate()

include("server.jl")
include("modeling.jl")

# 启动服务，本地测试通过命令行传参启动：julia main.jl true
julia_main(isempty(ARGS))