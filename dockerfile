# 使用官方的Node.js镜像作为构建前端的基础镜像
FROM node:18 AS frontend-builder

# 设置工作目录
WORKDIR /app/frontend

# 复制项目文件并构建前端应用
COPY . .
RUN npm install
RUN npm run build

# 使用官方的Nginx镜像作为运行时环境
FROM nginx:alpine

# 从上一阶段复制构建好的前端应用到Nginx的默认静态文件目录
COPY --from=frontend-builder /app/frontend/dist /usr/share/nginx/html

# 暴露3000端口
EXPOSE 3000

# 配置Nginx监听3000端口
RUN sed -i 's/80/3000/g' /etc/nginx/conf.d/default.conf

# 安装Julia
RUN apk add --no-cache julia

# 设置工作目录为后端代码位置
WORKDIR /app/julia-src

# 将后端代码复制到容器内
COPY julia-src ./julia-src

# 如果存在 Project.toml 和 Manifest.toml，则预编译依赖
RUN if [ -f "Project.toml" ] && [ -f "Manifest.toml" ]; then \
      julia --project=. -e 'import Pkg; Pkg.instantiate()'; \
    fi

# 启动脚本，同时启动Nginx和Julia后端
CMD service nginx start && julia --project=. julia-src/main.jl