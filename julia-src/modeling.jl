using JuMP, HiGHS

const T = 2 # 分辨率倍率，以小时级为基准，为1，2为半小时，30为分钟。

"""
根据不同时段定义电价。
- 尖峰电价：19.5-21.5小时
- 高峰电价：8-11.5小时 & 18.5-23小时
- 低谷电价：23-24小时 & 0-7小时
- 平段电价：其余时段
"""
function getPrices()
    # 定义尖、峰、平、谷电价
    peak_price = modelParas["尖峰电价"]
    off_peak_price = modelParas["高峰电价"]
    flat_price = modelParas["平段电价"]
    valley_price = modelParas["谷时电价"]

    # 初始化电价数组
    prices = Array{Float64}(undef, 24 * T)

    # 填充电价数组
    for hour in 0:(24*T-1)
        if 19.5 * T <= hour < 21.5 * T  # 尖峰时段，未考虑冬夏
            prices[hour+1] = peak_price
        elseif (8 * T <= hour < 11.5 * T) || (18.5 * T <= hour < 23 * T)  # 高峰时段
            prices[hour+1] = off_peak_price
        elseif (23 * T <= hour) || (hour < 7 * T)  # 低谷时段
            prices[hour+1] = valley_price
        else  # 平时段
            prices[hour+1] = flat_price
        end
    end
    # 输出电价数组
    return prices
end

"""
优化函数，用于计算最优的充电和放电策略。
- 使用HiGHS优化器
- 定义变量：input（充电功率）、output（放电功率）、storage（电池容量）
- 定义约束：电池容量的动态变化和初始/结束容量相同
- 目标函数：最大化收益（放电收益-充电成本）
"""
function optimize()
    @info "参数检测完毕..."
    # 24小时的充电代价，对应峰谷电价时刻表或者其他因素，长度为48的数组（半小时一记），以陕西夏季一般工商业电价为例
    COST = getPrices()
    # 24小时的放电收益，对应峰谷电价时刻表或者其他因素，长度为48的数组（半小时一记），以陕西夏季一般工商业电价为例，由于储能电站的效率为η，所以收益为电价的η倍
    GAIN = COST * modelParas["效率"]
    # 储能电站容量，kWh
    CAPACITY = modelParas["容量"]
    # 储能电站最大充电功率，kW
    MAXPOWER = modelParas["充放电倍率"] * CAPACITY
    @info "开始构建模型..."
    model = Model(HiGHS.Optimizer) # 使用HiGHS优化器
    @variable(model, MAXPOWER >= input[1:24*T] >= 0) # 每半小时充电功率
    @variable(model, MAXPOWER >= output[1:24*T] >= 0) # 每半小时放电功率
    @variable(model, CAPACITY >= storage[1:(24*T+1)] >= 0) # 电池容量，长度为48的数组
    @constraint(model, [t = 1:24*T], storage[t+1] == storage[t] + (1 / T) * (input[t] - output[t])) # 电池容量的约束
    @constraint(model, storage[1] == storage[24*T+1]) # 电池容量的初始值和结束值相同
    @objective(model, Max, sum(GAIN .* output - COST .* input)) # 最大化收益
    @info "开始优化..."
    optimize!(model)
    @info "返回结果..."
    if termination_status(model) == MOI.OPTIMAL
        return Dict(
            "status" => "SUCCESS",
            "totalRevenue" => round(objective_value(model) / T, digits=2),
            "chargeData" => value.(input),
            "dischargeData" => value.(output),
            "totalCharge" => round(sum(value.(input)) / T, digits=1),
            "storage" => value.(storage)
        )
    else
        return Dict(
            "status" => termination_status(model),
        )
    end
end

