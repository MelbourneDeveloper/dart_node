import syntaxHighlight from "@11ty/eleventy-plugin-syntaxhighlight";
import pluginRss from "@11ty/eleventy-plugin-rss";
import eleventyNavigationPlugin from "@11ty/eleventy-navigation";
import markdownIt from "markdown-it";
import markdownItAnchor from "markdown-it-anchor";
import { execSync } from "child_process";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packagesDir = resolve(__dirname, "..", "packages");

const supportedLanguages = ['en', 'zh'];
const defaultLanguage = 'en';

export default function(eleventyConfig) {
  // Don't use .gitignore to ignore files (we want to process generated docs)
  eleventyConfig.setUseGitIgnore(false);

  // Configure markdown-it with anchor plugin for header IDs
  const mdOptions = {
    html: true,
    breaks: false,
    linkify: true
  };

  const mdAnchorOptions = {
    permalink: markdownItAnchor.permalink.headerLink(),
    slugify: (s) => s.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]+/g, ''),
    level: [1, 2, 3, 4]
  };

  const md = markdownIt(mdOptions).use(markdownItAnchor, mdAnchorOptions);
  eleventyConfig.setLibrary("md", md);

  // Plugins
  eleventyConfig.addPlugin(syntaxHighlight);
  eleventyConfig.addPlugin(pluginRss);
  eleventyConfig.addPlugin(eleventyNavigationPlugin);

  // Passthrough copy for assets
  eleventyConfig.addPassthroughCopy("src/assets");
  eleventyConfig.addPassthroughCopy("src/api");
  eleventyConfig.addPassthroughCopy("src/robots.txt");

  // Watch targets
  eleventyConfig.addWatchTarget("src/assets/");

  // Watch READMEs and copy when they change
  eleventyConfig.addWatchTarget(packagesDir);
  eleventyConfig.on("eleventy.beforeWatch", (changedFiles) => {
    if (changedFiles.some(f => f.endsWith("README.md"))) {
      execSync("node scripts/copy-readmes.js", { stdio: "inherit" });
    }
  });

  // Collections
  eleventyConfig.addCollection("posts", function(collectionApi) {
    return collectionApi.getFilteredByGlob("src/blog/*.md").sort((a, b) => {
      return b.date - a.date;
    });
  });

  eleventyConfig.addCollection("docs", function(collectionApi) {
    return collectionApi.getFilteredByGlob("src/docs/**/*.md");
  });

  // Tag collection - get all unique tags from blog posts
  eleventyConfig.addCollection("tagList", function(collectionApi) {
    const tagSet = new Set();
    collectionApi.getFilteredByGlob("src/blog/*.md").forEach(post => {
      (post.data.tags || []).forEach(tag => {
        tag !== 'post' && tag !== 'posts' && tagSet.add(tag);
      });
    });
    return [...tagSet].sort();
  });

  // Category collection - get all unique categories from blog posts
  eleventyConfig.addCollection("categoryList", function(collectionApi) {
    const categorySet = new Set();
    collectionApi.getFilteredByGlob("src/blog/*.md").forEach(post => {
      post.data.category && categorySet.add(post.data.category);
    });
    return [...categorySet].sort();
  });

  // Posts by tag - creates a collection for each tag
  eleventyConfig.addCollection("postsByTag", function(collectionApi) {
    const postsByTag = {};
    collectionApi.getFilteredByGlob("src/blog/*.md").forEach(post => {
      (post.data.tags || []).forEach(tag => {
        tag !== 'post' && tag !== 'posts' && (postsByTag[tag] = postsByTag[tag] || []).push(post);
      });
    });
    Object.keys(postsByTag).forEach(tag => {
      postsByTag[tag].sort((a, b) => b.date - a.date);
    });
    return postsByTag;
  });

  // Posts by category - creates a collection for each category
  eleventyConfig.addCollection("postsByCategory", function(collectionApi) {
    const postsByCategory = {};
    collectionApi.getFilteredByGlob("src/blog/*.md").forEach(post => {
      post.data.category && (postsByCategory[post.data.category] = postsByCategory[post.data.category] || []).push(post);
    });
    Object.keys(postsByCategory).forEach(cat => {
      postsByCategory[cat].sort((a, b) => b.date - a.date);
    });
    return postsByCategory;
  });

  // Filters
  eleventyConfig.addFilter("dateFormat", (dateObj) => {
    return new Date(dateObj).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  });

  eleventyConfig.addFilter("isoDate", (dateObj) => {
    return new Date(dateObj).toISOString();
  });

  eleventyConfig.addFilter("limit", (arr, limit) => {
    return arr.slice(0, limit);
  });

  eleventyConfig.addFilter("capitalize", (str) => {
    return str ? str.charAt(0).toUpperCase() + str.slice(1) : '';
  });

  eleventyConfig.addFilter("slugify", (str) => {
    return str ? str.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]+/g, '') : '';
  });

  // i18n filter - get translation by key path
  eleventyConfig.addFilter("t", (key, lang = defaultLanguage) => {
    const i18n = eleventyConfig.globalData?.i18n;
    if (!i18n) return key;
    const langData = i18n[lang] || i18n[defaultLanguage];
    const keys = key.split('.');
    let value = langData;
    for (const k of keys) {
      value = value?.[k];
    }
    return value || key;
  });

  // Get alternate language URL
  eleventyConfig.addFilter("altLangUrl", (url, currentLang, targetLang) => {
    if (currentLang === 'en' && targetLang !== 'en') {
      return `/${targetLang}${url}`;
    } else if (currentLang !== 'en' && targetLang === 'en') {
      return url.replace(`/${currentLang}`, '') || '/';
    } else if (currentLang !== 'en' && targetLang !== 'en') {
      return url.replace(`/${currentLang}`, `/${targetLang}`);
    }
    return url;
  });

  // Add global data for languages
  eleventyConfig.addGlobalData("supportedLanguages", supportedLanguages);
  eleventyConfig.addGlobalData("defaultLanguage", defaultLanguage);

  // Shortcodes
  eleventyConfig.addShortcode("year", () => `${new Date().getFullYear()}`);

  return {
    dir: {
      input: "src",
      output: "_site",
      includes: "_includes",
      data: "_data"
    },
    templateFormats: ["md", "njk", "html"],
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk"
  };
}
