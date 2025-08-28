#!/usr/bin/env bash
#
# create new post with datetime stamp

set -x

echo "---
title: New Post
date: $(date +%Y-%m-%d\ %H:%M:%S\ +0800)
toc: true
categories: [AI, Programming]
tags: [Claude Code, CCR]
---
" > _posts/$(date +%Y-%m-%d)-new-post.md
