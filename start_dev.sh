#!/bin/bash
set -e

echo "========================================"
echo "  文件传输助手 - 开发模式启动"
echo "========================================"

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "已创建 .env 文件，请填入 ANTHROPIC_API_KEY 后重新运行"
    exit 1
fi

export $(grep -v '^#' .env | xargs)
export PYTHONPATH=$(pwd)

echo "安装 Python 依赖..."
pip install -r requirements.txt -q

echo "安装前端依赖..."
cd frontend && [ ! -d node_modules ] && npm install; cd ..

echo "启动后端 (port 8000)..."
uvicorn backend.main:app --reload --port 8000 &
BACKEND_PID=$!

echo "启动前端 (port 5173)..."
cd frontend && npm run dev &
FRONTEND_PID=$!

echo ""
echo "后端: http://localhost:8000"
echo "前端: http://localhost:5173"
echo "API文档: http://localhost:8000/docs"
echo ""
echo "Ctrl+C 停止所有服务"

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM
wait
