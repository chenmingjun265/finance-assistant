# 多 MCP 协同金融智能体系统

这是一个基于 **OpenAI Agents SDK + MCP（Model Context Protocol）** 的金融多智能体演示项目。系统由主路由智能体协调多个领域智能体，并通过 4 个独立 MCP 服务完成股票分析、金融咨询、金融文章审查和模拟转人工。

> 本项目用于课程实践、技术学习与作品集展示。股票预测与金融回答仅为技术演示，不构成投资建议。

## 项目功能

- 多智能体路由与 Handoff：根据用户意图切换到对应领域智能体。
- 股票分析 MCP：查询收盘价趋势、预测未来价格、生成投资分析报告。
- 金融咨询 MCP：本地投资政策 RAG 检索与可选的百炼应用检索。
- 文章审查 MCP：对 DOCX 金融文章进行基础审查、专业风险审查、报告生成与改写。
- 转人工 MCP：模拟将任务转交给人工服务。
- 多轮会话：使用 `session_id` 保存不同用户的对话状态。
- Web 与 API：提供 Gradio 聊天页面和 FastAPI 接口。

## 系统结构

```text
用户
 ├─ Gradio：gradio_demo.py（9996）
 └─ FastAPI：chat_api.py（9998）
          │
          ▼
multi_user_finance_assistant_main_with_session.py
          │
          ├─ 股票分析 MCP      stock_predict_mcp_server.py（8336）
          ├─ 金融咨询 MCP      finance_consult_mcp_server.py（9339）
          ├─ 文章审查 MCP      article_check_mcp_server.py（9330）
          └─ 模拟转人工 MCP    turn_human_server.py（8335）
```

## 目录说明

```text
.
├─ multi_user_finance_assistant_main_with_session.py  # 多用户主程序
├─ finance_assistant_main.py                           # 单用户主程序
├─ stock_predict_mcp_server.py                         # 股票分析 MCP
├─ finance_consult_mcp_server.py                       # 金融咨询 MCP / RAG
├─ article_check_mcp_server.py                         # 金融文章审查 MCP
├─ turn_human_server.py                                # 模拟转人工 MCP
├─ function_handler.py                                 # 公共模型与计算函数
├─ gradio_demo.py                                      # Gradio 页面
├─ chat_api.py                                         # FastAPI 服务
├─ chat_api_post.py                                    # API 请求示例
├─ start_all_mcp_servers.*                             # Windows 一键后台启动脚本
├─ stop_all_mcp_servers.*                              # Windows 一键停止脚本
├─ stock_data.xlsx                                     # 示例股票数据
├─ 投资政策.xlsx                                       # RAG 示例政策数据
└─ 全球增长基金的表现与风险分析.docx                   # 文章审查示例
```

运行时生成的 `.mcp_runtime/`、`db_data/`、`.gradio/` 和缓存目录均已通过 `.gitignore` 排除。

## 环境要求

- Python 3.11
- Conda（推荐，现有 `travel` 环境可以直接使用）
- DeepSeek API Key
- 阿里云百炼 DashScope API Key
- 可选：百炼应用的 App ID 与 API Key

## 安装与配置

进入项目目录并激活环境：

```powershell
conda activate travel
python -m pip install -r requirements.txt
```

从示例文件创建本机配置：

```powershell
Copy-Item .env.example .env
```

然后编辑 `.env`，填写自己的密钥：

```dotenv
server_url=127.0.0.1
DEEPSEEK_API_KEY=your_deepseek_api_key
API_KEY=your_dashscope_api_key
APP_ID=your_dashscope_app_id
APP_API_KEY=your_dashscope_app_api_key
```

`.env` 已被 Git 忽略，绝对不要将真实密钥写入 `.env.example` 或提交到 GitHub。

## 运行项目

### 1. 启动 4 个 MCP 服务

双击：

```text
start_all_mcp_servers.bat
```

也可以在已激活 `travel` 环境的 PowerShell 中运行：

```powershell
.\start_all_mcp_servers.ps1
```

脚本会在后台启动 4 个服务，不会打开多个终端。日志和 PID 文件位于 `.mcp_runtime/`。

| MCP 服务 | 端口 | 工具数 |
|---|---:|---:|
| 模拟转人工 | 8335 | 1 |
| 股票分析 | 8336 | 3 |
| 文章审查 | 9330 | 4 |
| 金融咨询 | 9339 | 2 |

### 2. 启动 Gradio 页面

```powershell
python gradio_demo.py
```

浏览器访问：<http://127.0.0.1:9996>

### 3. 启动 FastAPI（可选）

```powershell
python chat_api.py
```

接口地址：`POST http://127.0.0.1:9998/finance_MultiAgent_MultiMCP`

请求示例：

```json
{
  "current_message": "查询上证指数近期趋势",
  "session_id": ""
}
```

首次请求可将 `session_id` 留空；后续请求携带返回的会话 ID，即可继续多轮对话。也可以运行 `python chat_api_post.py` 使用项目自带的请求示例。

### 4. 停止 MCP 服务

双击 `stop_all_mcp_servers.bat`，或执行：

```powershell
.\stop_all_mcp_servers.ps1
```

## 上传 GitHub 前的安全检查

先初始化本地 Git 仓库（这一步不会上传任何文件）：

```powershell
git init
git branch -M main
```

然后确认敏感文件会被忽略：

```powershell
git check-ignore -v .env .mcp_runtime db_data .gradio
```

再检查准备提交的文件：

```powershell
git status --short
git diff --cached --name-only
```

重点确认列表中没有 `.env`、日志、PID、Chroma 数据库、缓存以及任何真实 API Key。

## 自己上传到 GitHub

1. 在 GitHub 页面创建一个空仓库，例如 `multi-mcp-finance-agent`，不要勾选自动创建 README。
2. 在本项目目录执行：

```powershell
git add .
git status
git commit -m "feat: initial multi-MCP finance agent project"
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

3. 刷新 GitHub 仓库页面，确认 README 正常显示，并再次确认仓库中没有 `.env`。

如果 GitHub 要求认证，请使用浏览器登录、Git Credential Manager 或 Personal Access Token，不要把 GitHub 密码/Token 写入项目文件。

## 已知限制

- 当前会话状态保存在进程内存中，服务重启后会丢失。
- 示例股票预测属于教学算法，不适用于真实交易决策。
- RAG 首次运行会初始化本地 Chroma 数据库，因此启动或首次查询可能较慢。
- 外部模型服务的可用性、额度与网络代理会影响调用结果。

## 数据与版权说明

公开仓库前，请确认示例 Excel、DOCX 和课程代码拥有公开发布权限；无法确认时，应替换为自己制作的脱敏示例数据。
