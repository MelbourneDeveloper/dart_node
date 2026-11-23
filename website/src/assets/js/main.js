/**
 * dart_node website main JavaScript
 * Dark mode toggle, mobile navigation, and utilities
 */

(function() {
  'use strict';

  // Theme toggle
  const themeToggle = document.getElementById('theme-toggle');
  const html = document.documentElement;

  // Check for saved theme preference or system preference
  const getPreferredTheme = () => {
    const saved = localStorage.getItem('theme');
    if (saved) return saved;

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };

  // Apply theme
  const setTheme = (theme) => {
    html.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  };

  // Initialize theme
  setTheme(getPreferredTheme());

  // Toggle theme on button click
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = html.getAttribute('data-theme');
      setTheme(current === 'dark' ? 'light' : 'dark');
    });
  }

  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      setTheme(e.matches ? 'dark' : 'light');
    }
  });

  // Mobile menu toggle
  const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
  const navLinks = document.querySelector('.nav-links');

  if (mobileMenuToggle && navLinks) {
    mobileMenuToggle.addEventListener('click', () => {
      navLinks.classList.toggle('open');
      mobileMenuToggle.classList.toggle('active');
    });

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!navLinks.contains(e.target) && !mobileMenuToggle.contains(e.target)) {
        navLinks.classList.remove('open');
        mobileMenuToggle.classList.remove('active');
      }
    });
  }

  // Docs sidebar toggle (mobile)
  const docsSidebar = document.getElementById('docs-sidebar');
  if (docsSidebar) {
    // Create toggle button for mobile
    const sidebarToggle = document.createElement('button');
    sidebarToggle.className = 'sidebar-toggle';
    sidebarToggle.innerHTML = 'Menu';
    sidebarToggle.style.cssText = `
      display: none;
      position: fixed;
      bottom: var(--space-4);
      right: var(--space-4);
      padding: var(--space-3) var(--space-6);
      background: var(--color-primary);
      color: white;
      border: none;
      border-radius: var(--radius-full);
      font-weight: 500;
      cursor: pointer;
      z-index: 60;
      box-shadow: var(--shadow-lg);
    `;

    document.body.appendChild(sidebarToggle);

    // Show toggle on mobile
    const checkMobile = () => {
      sidebarToggle.style.display = window.innerWidth <= 1024 ? 'block' : 'none';
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);

    sidebarToggle.addEventListener('click', () => {
      docsSidebar.classList.toggle('open');
      sidebarToggle.innerHTML = docsSidebar.classList.contains('open') ? 'Close' : 'Menu';
    });
  }

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // Add copy button to code blocks
  document.querySelectorAll('pre').forEach(pre => {
    const wrapper = document.createElement('div');
    wrapper.style.position = 'relative';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy-btn';
    copyBtn.innerHTML = 'Copy';
    copyBtn.style.cssText = `
      position: absolute;
      top: var(--space-2);
      right: var(--space-2);
      padding: var(--space-1) var(--space-3);
      font-size: var(--text-xs);
      background: var(--bg-tertiary);
      border: 1px solid var(--border-color);
      border-radius: var(--radius-sm);
      cursor: pointer;
      opacity: 0;
      transition: opacity var(--transition-fast);
    `;

    wrapper.appendChild(copyBtn);

    wrapper.addEventListener('mouseenter', () => {
      copyBtn.style.opacity = '1';
    });

    wrapper.addEventListener('mouseleave', () => {
      copyBtn.style.opacity = '0';
    });

    copyBtn.addEventListener('click', async () => {
      const code = pre.querySelector('code');
      const text = code ? code.textContent : pre.textContent;

      try {
        await navigator.clipboard.writeText(text);
        copyBtn.innerHTML = 'Copied!';
        setTimeout(() => {
          copyBtn.innerHTML = 'Copy';
        }, 2000);
      } catch (err) {
        copyBtn.innerHTML = 'Failed';
      }
    });
  });

  // Add heading anchors for docs
  document.querySelectorAll('.docs-content h2, .docs-content h3, .blog-post-content h2, .blog-post-content h3').forEach(heading => {
    if (heading.id) {
      const anchor = document.createElement('a');
      anchor.href = `#${heading.id}`;
      anchor.className = 'heading-anchor';
      anchor.innerHTML = '#';
      anchor.style.cssText = `
        margin-left: var(--space-2);
        color: var(--text-tertiary);
        text-decoration: none;
        opacity: 0;
        transition: opacity var(--transition-fast);
      `;

      heading.style.position = 'relative';
      heading.appendChild(anchor);

      heading.addEventListener('mouseenter', () => {
        anchor.style.opacity = '1';
      });

      heading.addEventListener('mouseleave', () => {
        anchor.style.opacity = '0';
      });
    }
  });

})();
