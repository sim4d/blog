# frozen_string_literal: true
#
# Inject macOS-style code block title bar into all HTML pages
# Works on Cloudflare Pages without needing to import theme SCSS

CSS_SNIPPET = <<~CSS
<style id="macos-codebar-css">
:root {
  --codebar-height: 32px;
  --codebar-radius: 10px;
}

/* Base code block container (Rouge/Chirpy wraps code in .highlight) */
.highlight {
  position: relative;
  border-radius: var(--codebar-radius);
  overflow: hidden;
  /* Fallback bar when there is no separate header */
  padding-top: var(--codebar-height);
  /* Ensure no grayscale/filters from theme affect colors */
  -webkit-filter: none !important;
  filter: none !important;
}

/* Fallback: draw the macOS bar on the code block itself */
.highlight::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0;
  height: var(--codebar-height);
  background: linear-gradient(180deg, #f5f5f7, #e6e6ea);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  z-index: 1;
}
.highlight::after {
  content: "";
  position: absolute;
  top: calc(var(--codebar-height) / 2);
  left: 12px;
  width: 12px; height: 12px;
  border-radius: 50%;
  transform: translateY(-50%);
  background: #ff5f56; /* red */
  box-shadow: 16px 0 0 #ffbd2e, /* yellow */
              32px 0 0 #27c93f; /* green */
  z-index: 2;
  /* Force color rendering */
  -webkit-filter: none !important;
  filter: none !important;
  mix-blend-mode: normal !important;
  opacity: 1 !important;
  pointer-events: none;
}

/* If a separate header exists before the block, remove fallback */
.code-header + .highlight { padding-top: 0; border-top-left-radius: 0; border-top-right-radius: 0; }
.code-header + .highlight::before, .code-header + .highlight::after { display: none; }

/* Progressive enhancement: header inside container */
.highlight:has(.code-header) { padding-top: 0; }
.highlight:has(.code-header)::before, .highlight:has(.code-header)::after { display: none; }

/* Separate header styling */
.code-header {
  position: relative;
  height: var(--codebar-height);
  line-height: var(--codebar-height);
  padding-left: 56px; /* space for macOS buttons */
  padding-right: 8px;
  border: 1px solid rgba(0,0,0,0.08);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  background: linear-gradient(180deg, #f5f5f7, #e6e6ea);
  border-top-left-radius: var(--codebar-radius);
  border-top-right-radius: var(--codebar-radius);
  /* Layout fixes to avoid overlaps */
  display: flex;
  align-items: center;
  gap: 8px;
  /* Ensure no grayscale/filters from theme affect colors */
  -webkit-filter: none !important;
  filter: none !important;
  z-index: 0;
}
.code-header::before {
  content: "";
  position: absolute;
  top: 50%; left: 12px;
  width: 12px; height: 12px;
  border-radius: 50%;
  transform: translateY(-50%);
  background: #ff5f56; /* red */
  box-shadow: 16px 0 0 #ffbd2e, /* yellow */
              32px 0 0 #27c93f; /* green */
  z-index: 1;
}
/* Ensure header content lays above the pseudo element and doesn't overlap */
.code-header > * { position: relative; z-index: 2; }

/* Language label and copy button behavior */
.code-header .code-lang, .code-header .lang {
  opacity: .85;
  font-size: .85em;
  position: relative !important;
  left: auto !important;
  margin-left: 0 !important;
}
/* Place copy button on the far right in flex layout */
.code-header .copy-btn, .code-header .btn-copy {
  margin-left: auto;
  float: none;
}

@media (prefers-color-scheme: dark) {
  .code-header, .highlight::before {
    background: linear-gradient(180deg, #3a3a3c, #2f2f31);
    border-bottom-color: rgba(255,255,255,0.06);
  }
}
</style>
CSS

module Jekyll
  module MacOSCodebar
    def self.inject!(html)
      return html unless html&.include?("</head>")
      return html if html.include?("macos-codebar-css")
      html.sub("</head>", CSS_SNIPPET + "\n</head>")
    end
  end
end

# Hook for pages, posts, and documents
Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.output_ext == ".html"
  page.output = Jekyll::MacOSCodebar.inject!(page.output)
end

Jekyll::Hooks.register :posts, :post_render do |post|
  next unless post.output_ext == ".html"
  post.output = Jekyll::MacOSCodebar.inject!(post.output)
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  next unless doc.respond_to?(:output_ext) && doc.output_ext == ".html"
  doc.output = Jekyll::MacOSCodebar.inject!(doc.output)
end
