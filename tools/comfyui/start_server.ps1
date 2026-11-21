# Starts the local ComfyUI server (loopback only). ComfyUI lives outside the repo.
param([string]$Root = "E:\Tools\ComfyUI")
Set-Location $Root
& "$Root\venv\Scripts\python.exe" main.py --listen 127.0.0.1 --port 8188
