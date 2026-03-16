import fs from 'node:fs';
import path from 'node:path';

export function contentResolver() {
  let root = '';
  let contentFiles = [];

  return {
    name: 'content-resolver',

    configResolved(config) {
      root = config.root;
    },

    configureServer(server) {
      server.watcher.on('change', file => {
        if (contentFiles.some(f => file.endsWith(f))) {
          console.log(
            `✓ Content file changed: ${path.basename(file)}, reloading...`
          );
          server.ws.send({ type: 'full-reload' });
        }
      });
    },

    transformIndexHtml: {
      order: 'pre',
      handler(html, ctx) {
        const scriptRegex =
          /<script[^>]*\bid=["']content["'][^>]*type=["']application\/json["'][^>]*>([\s\S]*?)<\/script>|<script[^>]*type=["']application\/json["'][^>]*\bid=["']content["'][^>]*>([\s\S]*?)<\/script>/;
        const match = html.match(scriptRegex);

        if (!match) {
          console.log(
            'content-resolver: No content script tag found, skipping'
          );
          return html;
        }

        const scriptContent = match[1] || match[2];

        if (!scriptContent || !scriptContent.trim()) {
          console.log('content-resolver: Script tag is empty, skipping');
          return html;
        }

        let rawContent;
        try {
          rawContent = JSON.parse(scriptContent);
        } catch (e) {
          console.error(
            'content-resolver: Failed to parse content JSON:',
            e.message
          );
          console.error(
            'content-resolver: Script content was:',
            scriptContent.substring(0, 100)
          );
          return html;
        }

        contentFiles = [];

        for (const key in rawContent) {
          const filePath = rawContent[key];
          if (typeof filePath === 'string' && filePath.endsWith('.json')) {
            const absolutePath = path.resolve(root, filePath);
            contentFiles.push(filePath);

            if (ctx.server) {
              ctx.server.watcher.add(absolutePath);
            }

            try {
              const fileContent = JSON.parse(
                fs.readFileSync(absolutePath, 'utf-8')
              );
              rawContent[key] = fileContent;
            } catch (e) {
              console.error(
                `content-resolver: Failed to read/parse ${filePath}:`,
                e.message
              );
            }
          }
        }

        const resolvedJson = JSON.stringify(rawContent, null, 2);
        const newScriptTag = `<script id="content" type="application/json">${resolvedJson}</script>`;

        return html.replace(match[0], newScriptTag);
      },
    },
  };
}
