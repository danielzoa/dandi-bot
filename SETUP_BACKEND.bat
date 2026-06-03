@echo off
echo ============================================
echo   Dandi Bot - Setup Backend TradingAgents
echo ============================================
echo.

:: 1. Verificar Python
echo [1/5] Verificando Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Python nao encontrado!
    echo Instale Python 3.13 de: https://www.python.org/downloads/
    echo Marque "Add Python to PATH" durante a instalacao.
    pause
    exit /b 1
)
python --version
echo.

:: 2. Clonar TradingAgents (se nao existir)
echo [2/5] Verificando repositorio TradingAgents...
if exist "TradingAgents" (
    echo Repositorio ja existe. Atualizando...
    cd TradingAgents
    git pull
) else (
    echo Clonando TradingAgents...
    git clone https://github.com/TauricResearch/TradingAgents.git
    cd TradingAgents
)
echo.

:: 3. Criar venv e instalar dependencias
echo [3/5] Criando ambiente virtual e instalando dependencias...
if not exist "venv" (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install --upgrade pip
pip install .
pip install fastapi uvicorn[standard]
echo.

:: 4. Copiar api_server.py
echo [4/5] Copiando api_server.py...
if exist "..\api_server.py" (
    copy /Y "..\api_server.py" "api_server.py"
    echo api_server.py copiado com sucesso.
) else (
    echo AVISO: api_server.py nao encontrado na raiz do Dandi Bot.
    echo Copie manualmente de: Desktop\Dandi Bot\bugs\files\api_server.py
)
echo.

:: 5. Iniciar servidor
echo [5/5] Iniciando servidor FastAPI...
echo.
echo ============================================
echo   Backend disponivel em:
echo   http://127.0.0.1:8000/api/health
echo   http://127.0.0.1:8000/docs
echo ============================================
echo.
echo Pressione Ctrl+C para parar o servidor.
echo.
uvicorn api_server:app --reload --port 8000
