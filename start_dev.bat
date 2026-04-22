@echo off
echo ========================================
echo   文件传输助手 - 开发模式启动
echo ========================================

if not exist ".env" (
    echo 正在创建 .env 文件...
    copy .env.example .env
    echo 请编辑 .env 文件，填入 ANTHROPIC_API_KEY
    pause
    exit /b
)

echo 安装 Python 依赖...
pip install -r requirements.txt

echo 启动后端...
start cmd /k "set PYTHONPATH=%CD% && uvicorn backend.main:app --reload --port 8000"

echo 安装前端依赖...
cd frontend
if not exist "node_modules" npm install
echo 启动前端...
start cmd /k "npm run dev"
cd ..

echo.
echo 后端: http://localhost:8000
echo 前端: http://localhost:5173
echo API文档: http://localhost:8000/docs
echo.
pause
