import { readFileSync } from "fs";
import { execSync } from "child_process";
import { dirname, resolve, join } from "path";
import { fileURLToPath } from "url";

// Import plugin submodules via file paths (workaround for #9:
// virtual templates override local layouts, so we register non-layout
// virtual templates separately. Package only exports "." so we use
// direct file paths.)
import { registerFilters } from "./node_modules/eleventy-plugin-techdoc/lib/filters/index.js";
import { registerCollections } from "./node_modules/eleventy-plugin-techdoc/lib/plugins/collections.js";
import { registerShortcodes } from "./node_modules/eleventy-plugin-techdoc/lib/shortcodes/index.js";
import { configureMarkdown } from "./node_modules/eleventy-plugin-techdoc/lib/plugins/markdown.js";
import syntaxHighlight from "@11ty/eleventy-plugin-syntaxhighlight";
import rss from "@11ty/eleventy-plugin-rss";
import navigation from "@11ty/eleventy-navigation";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packagesDir = resolve(__dirname, "..", "packages");

const techdocOptions = {
  site: {
    name: "dart_node",
    title: "dart_node - Full-Stack Dart for the JavaScript Ecosystem",
    url: "https://dartnode.dev",
    description: "Write React, React Native, and Express apps entirely in Dart. One language for frontend, backend, and mobile.",
    author: "dart_node team",
    themeColor: "#0E7C6B",
    stylesheet: "/assets/css/styles.css",
    twitterSite: "@dart_node",
    twitterCreator: "@dart_node",
    ogImage: "/assets/images/og-image.png",
    ogImageWidth: "1200",
    ogImageHeight: "630",
    organization: {
      name: "dart_node",
      logo: "/assets/images/og-image.png",
      sameAs: [
        "https://github.com/melbournedeveloper/dart_node",
        "https://twitter.com/dart_node",
        "https://pub.dev/publishers/dartnode.dev"
      ]
    }
  },
  features: {
    blog: true,
    docs: true,
    darkMode: true,
    i18n: true,
  },
  i18n: {
    defaultLanguage: "en",
    languages: ["en", "zh"],
  },
};

export default function(eleventyConfig) {
  eleventyConfig.setUseGitIgnore(false);

  // === techdoc plugin features (without layout virtual templates) ===
  // We use the plugin's filters, collections, shortcodes, markdown config,
  // and bundled plugins, but NOT its layout virtual templates because
  // dart_node's layouts are superior (see GitHub issue #9).

  // Global data (same as plugin sets)
  eleventyConfig.addGlobalData("techdocOptions", techdocOptions);
  eleventyConfig.addGlobalData("supportedLanguages", techdocOptions.i18n.languages);
  eleventyConfig.addGlobalData("defaultLanguage", techdocOptions.i18n.defaultLanguage);

  // Plugin submodules
  configureMarkdown(eleventyConfig);
  registerFilters(eleventyConfig, techdocOptions);
  registerCollections(eleventyConfig, techdocOptions);
  registerShortcodes(eleventyConfig);

  // Bundled plugins
  eleventyConfig.addPlugin(syntaxHighlight);
  eleventyConfig.addPlugin(rss);
  eleventyConfig.addPlugin(navigation);

  // Plugin structural CSS (no colors - site provides visual styling)
  const techdocAssetsDir = join(__dirname, "node_modules", "eleventy-plugin-techdoc", "assets");
  eleventyConfig.addPassthroughCopy({ [techdocAssetsDir]: "techdoc" });

  // Register only NON-LAYOUT virtual templates from the plugin
  // (feed, sitemap, robots.txt, llms.txt, blog scaffold pages)
  // Layouts come from our local src/_includes/layouts/ which are superior.
  registerSeoVirtualTemplates(eleventyConfig);

  // === Site-specific config ===
  eleventyConfig.addPassthroughCopy("src/assets");
  eleventyConfig.addPassthroughCopy("src/api");
  eleventyConfig.addWatchTarget("src/assets/");

  eleventyConfig.addWatchTarget(packagesDir);
  eleventyConfig.on("eleventy.beforeWatch", (changedFiles) => {
    if (changedFiles.some(f => f.endsWith("README.md"))) {
      execSync("node scripts/copy-readmes.js", { stdio: "inherit" });
    }
  });

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

/**
 * Register only SEO virtual templates from the techdoc plugin.
 * Layouts and blog scaffold pages come from local files (dart_node's are superior).
 */
function registerSeoVirtualTemplates(eleventyConfig) {
  const templatesDir = join(
    __dirname, "node_modules", "eleventy-plugin-techdoc", "templates"
  );

  eleventyConfig.addTemplate(
    "feed.njk",
    readFileSync(join(templatesDir, "pages/feed.njk"), "utf-8")
  );
  eleventyConfig.addTemplate(
    "sitemap.njk",
    readFileSync(join(templatesDir, "pages/sitemap.njk"), "utf-8")
  );
  eleventyConfig.addTemplate(
    "robots.txt.njk",
    readFileSync(join(templatesDir, "pages/robots.txt.njk"), "utf-8")
  );
  eleventyConfig.addTemplate(
    "llms.txt.njk",
    readFileSync(join(templatesDir, "pages/llms.txt.njk"), "utf-8")
  );
}
