export function metaInjector(options = {}) {
  let isBuild = false;

  return {
    name: 'meta-injector',

    configResolved(config) {
      isBuild = config.command === 'build';
      if (isBuild) {
        if (options.siteUrl) {
          console.log(
            `✓ Site URL meta tags will be injected: ${options.siteUrl}`
          );
        } else {
          console.log('⚠ Meta injector: No site URL provided - skipping');
        }
      }
    },

    transformIndexHtml: {
      order: 'pre',
      handler(html) {
        if (!isBuild) {
          return html;
        }

        if (!options.siteUrl) {
          return html;
        }

        const siteUrl = validateUrl(options.siteUrl);
        if (!siteUrl) {
          console.warn(
            '⚠ Meta injector: Invalid site URL provided - skipping'
          );
          return html;
        }

        let cleanedHtml = html;
        cleanedHtml = cleanedHtml.replace(
          /<link[^>]*\s+rel=["']canonical["'][^>]*\/?>/gi,
          ''
        );
        cleanedHtml = cleanedHtml.replace(
          /<meta[^>]*\s+property=["']og:url["'][^>]*\/?>/gi,
          ''
        );

        return {
          html: cleanedHtml,
          tags: [
            {
              tag: 'link',
              attrs: { rel: 'canonical', href: siteUrl },
              injectTo: 'head',
            },
            {
              tag: 'meta',
              attrs: { property: 'og:url', content: siteUrl },
              injectTo: 'head',
            },
          ],
        };
      },
    },
  };
}

function validateUrl(str) {
  if (typeof str !== 'string' || !str.trim()) {
    return null;
  }

  try {
    const url = new URL(str);
    return url.toString();
  } catch {
    return null;
  }
}
