using Oxygen, HTTP
import JSON

# 跨域请求头
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

# 定义一个常量字典，用于存储模型参数
const modelParas = Dict(
    "尖峰电价" => 1.095285,  # 尖峰时段的电价，单位：元/kWh
    "高峰电价" => 0.981225,  # 高峰时段的电价，单位：元/kWh
    "平段电价" => 0.671125,  # 平段时段的电价，单位：元/kWh
    "谷时电价" => 0.361025,  # 谷时时段的电价，单位：元/kWh
    "效率" => 0.8,          # 电池充放电效率
    "容量" => 100,          # 电池总容量，单位：kWh
    "充放电倍率" => 0.5      # 充放电倍率，表示电池的最大充放电功率为其容量的倍数
    # 例如，当电池容量为100kWh，充放电倍率为0.5时，最大充放电功率为100*0.5=50kW
)


"""
    CorsMiddleware(handler)

创建一个CORS中间件，用于处理跨域请求。

# 参数
- `handler`: 一个处理请求的函数，用于执行实际的请求处理逻辑。

# 返回值
返回一个闭包函数，该闭包函数将处理HTTP请求，并在特定条件下添加CORS头。

# 功能描述
此中间件主要用于处理跨域资源共享（CORS）请求。当接收到"POST"、"GET"或"OPTIONS"方法的请求时，
中间件会调用传入的`handler`函数处理请求，并在响应中添加全局的`CORS_HEADERS`头。
如果请求方法不属于上述三种方法，则直接将请求传递给`handler`进行处理，以便其他中间件或处理函数可以接管。
"""
function CorsMiddleware(handler)
    return function (req::HTTP.Request)
        # println("CORS middleware")
        # determine if this is a pre-flight request from the browser
        if HTTP.method(req) ∈ ["POST", "GET", "OPTIONS"]
            return HTTP.Response(200, CORS_HEADERS, HTTP.body(handler(req)))
        else
            return handler(req) # passes the request to the AuthMiddleware
        end
    end
end

"""
检查参数是否合法

该函数用于验证输入参数是否满足特定条件模型参数。它首先从输入的字典中提取有关电价、
容量、充放电倍率和效率的信息，并检查这些值是否都大于零且效率是否小于等于1。

参数:
- paras::Dict: 包含模型所需参数的字典，包括不同时间段的电价、容量、充放电倍率和效率。

返回值:
- Bool: 如果所有参数都满足条件，则返回true，否则返回false。
"""
function checkParasIsLegal(paras::Dict)
    # 从输入参数中提取模型所需的各个参数值
    modelParas["尖峰电价"] = paras["priceData"]["尖峰"]
    modelParas["高峰电价"] = paras["priceData"]["高峰"]
    modelParas["平段电价"] = paras["priceData"]["平段"]
    modelParas["谷时电价"] = paras["priceData"]["低谷"]
    modelParas["容量"] = paras["capacity"]
    modelParas["充放电倍率"] = paras["rate"]
    modelParas["效率"] = paras["eff"]
    
    # 检查所有参数值是否大于0且效率是否小于等于1
    if all(>(0), values(modelParas)) && modelParas["效率"] <= 1
        return true
    else
        return false
    end
end

function julia_main(async=true)
    # 后端服务相应路由，接受前端传入的参数，调用优化总函数，返回优化求解结果。
    @post "/optimize" function (req)
        # this will convert the request body into a Julia Dict
        paras = JSON.parse(String(req.body))
        @show paras
        # 返回数据，匹配前端request要求的格式
        if checkParasIsLegal(paras)
            # 调用后端模型获得数据
            data = optimize()
            if data["status"] == "SUCCESS"
                delete!(data, "status") # 删除status字段
                return Dict(
                    "code" => 200,
                    "message" => "success",
                    "data" => data
                )
            else
                return Dict(
                    "code" => 500,
                    "message" => "error",
                    "data" => "求解错误，状态码: " * data["status"]
                )
            end
        else
            return Dict(
                "code" => 404,
                "message" => "error",
                "data" => "参数输入不合法！检查所有参数值是否大于0且效率是否小于等于1！"
            )
        end
    end
    #测试路由，返回hello world
    @get "hello" function (req)
        return Dict(
            "code" => 200,
            "message" => "success",
            "data" => "hello world"
        )
    end

    @info "正在预编译......"
    # 开启服务前，先执行一次，等价于预编译
    begin
        paras = JSON.parse(read(joinpath(@__DIR__, "example.json"), String))
        checkParasIsLegal(paras)
        optimize()
    end
    @info "正在启动服务器......"
    # 本地测试 async=true，服务器上 async=false。异步测试便于调试
    serve(host="0.0.0.0", port=8082, async=async, middleware=[CorsMiddleware])

    @info "服务器启动成功！"
    return 0
end