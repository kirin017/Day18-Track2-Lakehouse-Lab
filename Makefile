## Day 18 Lakehouse Lab — student UX (Windows / PowerShell)
## Two paths: lightweight (default, pure Python) and Spark (Docker, optional).

SHELL        := powershell.exe
.SHELLFLAGS  := -NoProfile -NonInteractive -Command

VENV         := .venv
PY           := $(VENV)/Scripts/python.exe
PIP          := $(VENV)/Scripts/pip.exe
JUPYTER      := $(VENV)/Scripts/jupyter.exe
JUPYTEXT     := $(VENV)/Scripts/jupytext.exe
COMPOSE      := docker compose -f docker/docker-compose.yml

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────

help: ## Show this help
	@Write-Host ""
	@Write-Host "Usage:  make <target>"
	@Write-Host ""
	@Write-Host "Lightweight path (default, no Docker):"
	@Write-Host "  setup         [lite] Create venv + install deps"
	@Write-Host "  smoke         [lite] 5-second end-to-end smoke test"
	@Write-Host "  lab           [lite] Open Jupyter Lab on http://localhost:8888"
	@Write-Host "  data          [lite] Generate 200K-row Bronze sample for NB4"
	@Write-Host "  clean         [lite] Wipe venv + lakehouse data"
	@Write-Host ""
	@Write-Host "Spark / Docker path (optional):"
	@Write-Host "  spark-up      [spark] Start MinIO + Spark/Jupyter (Docker)"
	@Write-Host "  spark-smoke   [spark] Smoke test inside Spark container"
	@Write-Host "  spark-data    [spark] Generate 1M-row Bronze (Spark)"
	@Write-Host "  spark-down    [spark] Stop Docker stack"
	@Write-Host "  spark-clean   [spark] Stop AND wipe MinIO + ivy cache"
	@Write-Host ""

# ─────────────────────────────────────────────────────────────
# Lightweight path (default) — pure Python, no Docker, no JVM
# ─────────────────────────────────────────────────────────────

setup: ## [lite] Create venv + install deps (~80 MB, ~10s with pip / ~2s with uv)
	@if (Get-Command uv -ErrorAction SilentlyContinue) { uv venv $(VENV) } else { python -m venv $(VENV) }
	@if (Get-Command uv -ErrorAction SilentlyContinue) { uv pip install --python "$(PY)" -r requirements.txt } else { & "$(PIP)" install -q -r requirements.txt }
	@try { Get-ChildItem notebooks -Filter *.py | ForEach-Object { & "$(JUPYTEXT)" --to notebook --update $$_.FullName } } catch {}
	@Write-Host ""; Write-Host "  OK Setup complete. Run 'make smoke' then 'make lab'."

smoke: ## [lite] 5-second end-to-end smoke test
	@& "$(PY)" scripts/verify_lite.py

lab: ## [lite] Open Jupyter Lab on http://localhost:8888
	@try { Get-ChildItem notebooks -Filter *.py | ForEach-Object { & "$(JUPYTEXT)" --to notebook --update $$_.FullName } } catch {}
	@& "$(JUPYTER)" lab --notebook-dir=notebooks --ServerApp.token='' --no-browser

data: ## [lite] Generate 200K-row Bronze sample for NB4
	@& "$(PY)" scripts/generate_data_lite.py

clean: ## [lite] Wipe venv + lakehouse data
	@Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$(VENV)"
	@Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "_lakehouse"
	@Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "notebooks/.ipynb_checkpoints"

# ─────────────────────────────────────────────────────────────
# Spark + Docker path (optional, production-fidelity)
# ─────────────────────────────────────────────────────────────

spark-up: ## [spark] Start MinIO + Spark/Jupyter (Docker — first run pulls ~2 GB)
	@$(COMPOSE) up -d
	@Write-Host "  Jupyter -> http://localhost:8888 (token: lakehouse)"
	@Write-Host "  MinIO   -> http://localhost:9001 (minioadmin / minioadmin)"

spark-smoke: ## [spark] Smoke test inside Spark container
	@$(COMPOSE) exec -T spark python /workspace/scripts/verify.py

spark-data: ## [spark] Generate 1M-row Bronze (Spark version)
	@$(COMPOSE) exec -T spark python /workspace/scripts/generate_data.py

spark-down: ## [spark] Stop Docker stack (data persists)
	@$(COMPOSE) down

spark-clean: ## [spark] Stop AND wipe MinIO + ivy cache
	@$(COMPOSE) down -v

.PHONY: help setup smoke lab data clean spark-up spark-smoke spark-data spark-down spark-clean
