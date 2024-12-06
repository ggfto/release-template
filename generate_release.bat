@echo off
setlocal enabledelayedexpansion

:: Atualiza o repositório local
git fetch --all --tags

:: Detecta a branch principal automaticamente
set "main_branch="
call :get_main_branch
if "%main_branch%"=="" (
    echo [Erro] Nao foi possivel detectar a branch principal. Certifique-se de estar no diretorio correto do repositorio Git.
    exit /b 1
)

echo [Info] Branch principal detectada: %main_branch%

:: Obtém a última tag e sugere a próxima versão
set "last_tag="
call :get_last_tag
call :calculate_next_version

echo [Info] Ultima tag encontrada: %last_tag%
echo [Info] Sugestao de nova tag: %next_version%

:: Permite ao usuario inserir uma versão personalizada
set /p "tag_version=Digite a versao da tag (%next_version%): "
if "%tag_version%"=="" set "tag_version=%next_version%"

:: Valida o formato da versão
echo %tag_version% | findstr /r "^v[0-9]\+\.[0-9]\+\.[0-9]\+$" >nul
if errorlevel 1 (
    echo [Erro] Formato da tag invalido. Use o formato vX.Y.Z (exemplo: v1.0.1).
    exit /b 1
)

:: Cria a tag no Git
echo [Info] Criando tag %tag_version% na branch '%main_branch%'...
git tag "%tag_version%" "%main_branch%"
if errorlevel 1 (
    echo [Erro] Falha ao criar a tag. Verifique se ela ja existe ou se voce tem permissoes adequadas.
    exit /b 1
)

:: Envia a tag para o repositório remoto
echo [Info] Enviando tag %tag_version% para o repositório remoto...
git push origin "%tag_version%"
if errorlevel 1 (
    echo [Erro] Falha ao enviar a tag. Verifique sua conexao e permissoes.
    exit /b 1
)

echo [Sucesso] Tag %tag_version% criada e enviada com sucesso!
exit /b

:get_main_branch
:: Obtém a branch principal (main ou master)
for /f "delims=" %%i in ('git symbolic-ref refs/remotes/origin/HEAD ^| findstr /r /v "^$" 2^>nul') do (
    set "main_branch=%%i"
)
set "main_branch=%main_branch:refs/remotes/origin/=%"
exit /b

:get_last_tag
:: Obtém a última tag do repositório
for /f "delims=" %%i in ('git describe --tags --abbrev=0 2^>nul') do (
    set "last_tag=%%i"
)

:: Alternativa caso o comando acima falhe
if "%last_tag%"=="" (
    for /f "delims=" %%j in ('git tag --sort=-v:refname ^| findstr /r /v "^$" 2^>nul') do (
        set "last_tag=%%j"
        goto :eof
    )
)
exit /b

:calculate_next_version
:: Calcula a próxima versão com base na última tag
if "%last_tag%"=="" (
    set "next_version=v1.0.0"
) else (
    for /f "tokens=1-3 delims=." %%a in ("%last_tag:v=%") do (
        set /a patch=%%c + 1
        set "next_version=v%%a.%%b.!patch!"
    )
)
exit /b
