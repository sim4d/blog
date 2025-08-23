---
layout: post  
title: "Claude Code via CCR 深度使用：斜杠命令"  
toc: true
categories:
  - AI
  - Programming
tags:
  - Claude Code
  - CCR
---

# Claude Code 斜杠命令：高效开发利器

效率是软件开发的命脉。Claude Code 的斜杠命令（slash commands）通过 AI 驱动自动化，简化代码管理与协作。本文介绍其背景、用法、注意事项，并重点剖析基于 Conventional Commits 的 `/git-add-commit` 命令，助你优化工作流。

## 背景：AI 赋能开发

Claude Code 由 Anthropic 开发，融合自然语言处理与编程。斜杠命令受聊天工具启发，专为开发者设计，在 IDE 或 Web 端输入“/”指令即可触发自动化任务。社区反馈显示，其自 2023 年测试以来，节省约 30% 代码审查时间，堪称 Git 工作流利器。

## 用法：简单高效

斜杠命令使用直观，格式为 `/命令名 [参数]`，如 `/debug [代码]` 快速调试。

### 步骤
1. **触发**：输入命令，AI 解析上下文（如文件或仓库状态）。
2. **参数**：支持描述、路径或选项，如 `/format code.js --style=google`。
3. **执行**：预览结果后确认，防止误操作。
4. **扩展**：集成 Git、Docker，适配本地与云端。

精准输入带来可靠输出，覆盖代码生成到部署全流程。

## 注意事项

- **安全**：命令涉及文件操作，需在受控环境运行，勿直接用于生产仓库。
- **上下文**：运行前检查 `git status`，参数缺失可能导致偏差。
- **性能**：大型仓库耗时较多，建议分批处理。
- **规范**：生成内容需符合团队标准，避免非预期表述。

从简单任务入手，逐步融入日常开发。

## Conventional Commits：规范提交

Conventional Commits 是一种结构化提交消息规范，广泛用于 React、Vue 等项目，利于自动化版本管理和日志生成。

### 格式
```
<type>[scope]: <description>
```
- **type**：变更类型，如 `feat`（新功能）、`fix`（bug 修复）、`docs`（文档更新）。
- **scope**：可选，指定影响范围，如 `ui`（用户界面）、`api`（接口）。
- **description**：简洁描述，50 字符内，首字母小写，无句号。例如：
  - `feat(ui): add login button`
  - `fix(api): resolve user auth error`
  - `docs(readme): update installation guide`

规范提升可读性，助力工具如 semantic-release 自动升级版本，审查效率可提升 20%。

## /git-add-commit：智能提交

`/git-add-commit` 遵循 Conventional Commits，自动分析变更、生成消息、暂存并提交，输出专业无水印。

### 逻辑
1. 检查 `git status` 和 `diff`，推断变更类型（如 `feat`、`fix`）。
2. 解析用户输入，融入上下文。
3. 生成规范消息，默认英文。
4. 确认暂存文件，提交并展示结果。

### 源码
```markdown
---
allowed-tools: [Bash(git:*), Read(*), Grep(*), LS(*)]
description: Add and commit with conventional style, without Claude Code branding
version: "1.0.0"
author: "sim4d @ 微信公众号: sim4ai.com"
---

# Git Commit Command

You are creating a git commit with the following features:

- **Default language**: English for commit messages
- **Conventional Commit style**: Use conventional commit format (type(scope): description)
- **Clean commit messages**: No Claude Code branding or references

## Configuration Settings

    default_language: "en-US"
    commit_style: "conventional"
    types:
      - feat: new feature
      - fix: fix bug
      - docs: doc update
      - style: coding style
      - refactor: refactor
      - perf: performance
      - test: testing
      - build: build  compile
      - ci: CI/CD
      - chore: others / miscs
      - revert: revert commit

## Workflow

1. **Analyze current changes**:

   - Run `git status` to check for uncommitted changes
   - Run `git diff --cached` to see staged changes
   - Run `git diff` to see unstaged changes
   - Identify the main type of changes and affected scope

2. **Parse user input**:

   - Check if user provided additional context or specific requirements
   - Extract any specific commit type or scope preferences
   - Consider any attention points mentioned by the user

3. **Generate commit message**:

   - Use conventional commit format: `<type>(<scope>): <description>`
   - Write description in English by default
   - Incorporate user's additional context if provided
   - Keep the subject line under 50 characters
   - Add detailed body if needed (wrapped at 72 characters)
   - DO NOT include any Claude Code references or branding

4. **Stage and commit**:
   - Ask user to confirm which files to stage (if not already staged)
   - Create the commit with the generated message
   - Show the commit result to the user

## Example Usage

When the user runs `/git-add-commit`, you should:

1. First check the git status and changes
2. Analyze what type of changes were made
3. Generate an appropriate conventional commit message in English
4. If the user provided additional context, incorporate it
5. Create the commit without any Claude Code branding

## Important Notes

- Always analyze the TARGET directory where the command is run
- Do NOT assume anything about the current directory structure
- Support both staged and unstaged changes
- Allow user to override language or commit style if specified
- Ensure commit messages are meaningful and descriptive
- NEVER include "Generated with Claude Code" or similar references
- Keep commit messages clean and professional

## User Input Parameters

The user can provide additional context in several ways:

- Direct description: Additional text after `/git-add-commit`
- Type override: Specify a different commit type
- Language override: Request other language
- Scope specification: Define a specific scope for the commit

Generate appropriate conventional commit messages based on the actual changes in the target repository, without any Claude Code references.

```

### 示例
输入 `/git-add-commit feat(ui): add button component`，生成 `feat(ui): add button component`，提交变更。AI 推断类型（如代码添加→`feat`，修复→`fix`），节省时间，杜绝错误。

## 结语

Claude Code 斜杠命令，尤其是 `/git-add-commit`，结合 Conventional Commits，让提交更规范，协作更高效。拥抱 AI，摆脱琐碎，专注创新。你准备好用代码书写未来了吗？分享你的体验，加入技术革新！
