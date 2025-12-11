import syntaxHighlight from "@11ty/eleventy-plugin-syntaxhighlight";
import pluginRss from "@11ty/eleventy-plugin-rss";
import eleventyNavigationPlugin from "@11ty/eleventy-navigation";
import markdownIt from "markdown-it";
import markdownItAnchor from "markdown-it-anchor";

export default function(eleventyConfig) {
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
