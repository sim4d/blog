# frozen_string_literal: true
#
# Inject macOS-style code block title bar into all HTML pages
# Works on Cloudflare Pages without needing to import theme SCSS

CSS_SNIPPET = <<~CSS
<style id="macos-codebar-css">
:root {
  --codebar-left-padding: 40px;
  --codebar-height: 32px;
  --codebar-radius: 10px;
  --macos-dot-size: 12px;
  --macos-dot-gap: 20px;
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
.highlight pre {
  overflow-x: auto !important;
}
/* Aggressive filter reset on common wrappers to prevent greyscale inheritance */
figure.highlight, div.highlight, .highlight, .highlight *,
.code-header, .code-header * {
  -webkit-filter: none !important;
  filter: none !important;
  opacity: 1 !important;
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
  width: var(--macos-dot-size); height: var(--macos-dot-size);
  border-radius: 50%;
  transform: translateY(-50%);
  background: #ff5f56; /* red */
  box-shadow: calc(var(--macos-dot-size) + var(--macos-dot-gap)) 0 0 #ffbd2e, /* yellow */
              calc((var(--macos-dot-size) + var(--macos-dot-gap)) * 2) 0 0 #27c93f; /* green */
  z-index: 9;
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
  padding-left: calc(var(--codebar-left-padding)) !important; /* left padding; real dots inserted as first child */
  padding-right: 8px;
  border: 1px solid rgba(0,0,0,0.08);
  border-bottom: 1px solid rgba(0,0,0,0.08);
  background: linear-gradient(180deg, #f5f5f7, #e6e6ea) !important;
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
  top: 50%; left: calc(var(--codebar-left-padding));
  width: var(--macos-dot-size); height: var(--macos-dot-size);
  border-radius: 50%;
  transform: translateY(-50%);
  background: #ff5f56 !important; /* red */
  box-shadow: calc(var(--macos-dot-size) + var(--macos-dot-gap)) 0 0 #ffbd2e, /* yellow */
              calc((var(--macos-dot-size) + var(--macos-dot-gap)) * 2) 0 0 #27c93f; /* green */
  z-index: 1;
  -webkit-filter: none !important;
  filter: none !important;
  mix-blend-mode: normal !important;
  opacity: 1 !important;
}
/* Ensure header content lays above the pseudo element and doesn't overlap */
.code-header > * { position: relative; z-index: 2; }

/* Hide any theme-provided dot elements to avoid duplication */
.code-header .code-header-dots,
.code-header .code-header-dot,
.code-header .dots,
.code-header .traffic-lights,
.code-header .window-controls {
  display: none !important;
}

/* Language label and copy button behavior (broaden selectors) */
.code-header .code-lang,
.code-header .lang,
.code-header .language,
.code-header [class*="lang"],
.code-header .file-name {
  opacity: .9;
  font-size: .85em;
  position: static !important; /* let flex flow it */
  left: auto !important;
  margin-left: 0 !important;
  padding-left: 0 !important;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
.macos-dots{display:inline-flex;align-items:center;gap:0;margin-right:8px;margin-left:8px;line-height:0;}
.macos-dots .dot{width:var(--macos-dot-size);height:var(--macos-dot-size);border-radius:50%;-webkit-filter:none!important;filter:none!important;flex:0 0 auto;display:block;margin-right:var(--macos-dot-gap);} 
.macos-dots .dot:last-child{margin-right:0;}
.macos-dots .red{background:#ff5f56!important;}
.macos-dots .yellow{background:#ffbd2e!important;}
.macos-dots .green{background:#27c93f!important;}
.code-header::before{display:none!important;}
.highlight::after{display:none!important;}
.code-header{display:flex!important;align-items:center!important;}
.code-header .copy-btn,.code-header .btn-copy{margin-left:auto!important;float:none!important;}
.code-header .code-lang,.code-header .lang,.code-header .language,.code-header [class*="lang"],.code-header .file-name{margin-left:12px!important;}
.highlight{position:relative;}
.highlight>.macos-dots{position:absolute;top:calc(var(--codebar-height)/2);left:calc(var(--codebar-left-padding));transform:translateY(-50%);z-index:10;}
</style>
<script id="macos-codebar-js">
(function(){
  function createDots(){
    var md=document.createElement('span');md.className='macos-dots';
    var colors=['red','yellow','green'];
    for(var i=0;i<3;i++){var s=document.createElement('span');s.className='dot '+colors[i];md.appendChild(s);} 
    return md;
  }
  function ensureHeaderDots(){
    document.querySelectorAll('.code-header').forEach(function(h){
      if(!h.querySelector('.macos-dots')){
        h.insertBefore(createDots(), h.firstChild);
        // ensure label has left margin so it will not overlap
        var label=h.querySelector('.code-lang, .lang, .language, [class*="lang"], .file-name');
        if(label){ label.style.marginLeft = '8px'; }
      }
    });
  }
  function ensureFallbackDots(){
    document.querySelectorAll('figure.highlight, div.highlight, pre.highlight, .highlight').forEach(function(h){
      var prev=h.previousElementSibling;
      var hasHeader=(prev && prev.classList.contains('code-header')) || h.querySelector('.code-header');
      if(!hasHeader && !h.querySelector('.macos-dots')){
        h.appendChild(createDots());
      }
    });
  }
  function init(){ ensureHeaderDots(); ensureFallbackDots(); }
  if(document.readyState==='loading'){ document.addEventListener('DOMContentLoaded', init); }
  else { init(); }
})();
</script>
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
