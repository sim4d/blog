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

## 重点命令剖析：/git-add-commit 的强大与实现

`/git-add-commit` 命令专为 Git 提交设计，严格遵循 Conventional Commits 规范。它自动化分析变更、生成消息、暂存文档并提交，全程无品牌水印，确保专业输出。适用于有未提交变更的仓库，帮助快速创建规范 commit。

### 命令逻辑

检查 `git status` 和 `git diff`，分析变更类型（如 `feat` 或 `fix`）。

解析用户输入，融入额外上下文（如描述或类型覆盖）。

生成符合规范的 `commit` 消息，默认使用英文。

确认暂存文档并提交，展示结果。

### 源码展示

以下是 `/git-add-commit` 的完整实现，基于 Markdown 文档，供参考与自定义。如果显示格式不正确，请线上查看：

https://sim4ai.com/posts/claude-code-via-ccr-commands/

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


### 使用示例

在仓库中输入 `/git-add-commit feat(ui): add button component`，命令会分析变更，生成 `feat(ui): add new button component` 的消息并提交。若未暂存文档，用户可确认 `stage` 列表。命令通过 AI 推断变更类型（如代码添加→`feat`，bug 修复→`fix`），确保消息简洁规范。

## 结语：拥抱 AI，掌控代码未来

Claude Code 的斜杠命令，尤其是 `/git-add-commit`，不仅是工具，更是开发者向专业化迈进的桥梁。依托 Conventional Commits 规范，你的仓库将更易维护，团队协作更顺畅。作为码农，别让琐事拖累创新——立即使用这些命令，让 AI 成为你的可靠伙伴。未来属于高效者，你准备好用代码书写属于你的传奇了吗？欢迎在评论区分享你的使用心得，与开源社区一起推动技术进步！