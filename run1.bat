:::: 批处理代码

@echo off
::::::::::::: 1,先处理文本::::::::::
set conv_list=list.txt
set indir=ui

:: 切换到脚本所在目录
cd /d %~dp0

if "%1"=="" echo "usage: %0 替换列表文件 所在目录 [新替换文件] [输出目录]" & goto endrun
if "%2"=="" echo "usage: %0 替换列表文件 所在目录 [新替换文件] [输出目录]" & goto endrun
set conv_list=%1
set indir=%2

:: echo %conv_list%
:: echo %indir%

if not exist preprocessing.pl (
		echo "error:请保证perl脚本与批处理脚本在同一目录!" & goto endrun
)
if not exist convert.pl (
		echo "error:请保证perl脚本与批处理脚本在同一目录!" & goto endrun
)

:::::::::::: 2,转换文件:::::::::::::
if "%3"=="" (
	perl preprocessing.pl %1
) else (
	perl preprocessing.pl %1 %3
)
	
echo "请先检查新替换列表文件是否符合要求! 要继续执行吗？[Y/N]"
set /p var=

:: 解析替换列表的名称
for /f "delims=" %%i in ("%1") do (
set filep=%%~dpi
set filen=%%~nxi
)
:: echo %1
:: echo 文件夹为%filep%
:: echo 文件名为%filen%

if %var%==Y goto continuerun
if %var%==y (goto continuerun) else (exit /B)

:continuerun
	set new_conv_list=%3
	if "%3"=="" (
		set new_conv_list=new_%filen%
	) else (
		set new_conv_list=%3
	)
	
	:: echo %new_conv_list%
	
	if "%4"=="" (
		perl convert.pl %new_conv_list% %2 
	)	else (
		perl convert.pl %new_conv_list% %2 %4
	)

:endrun
	exit /B
