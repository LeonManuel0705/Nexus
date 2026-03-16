import { generateErrorPage } from './error-page-generator.js';


function extractErrorFromViteErrorPage(html) {
  let message = 'HTML parsing error';
  let frame = '';

  const messageMatch =
    html.match(/<pre[^>]*>([\s\S]*?)<\/pre>/i) ||
    html.match(/Error[:\s]*([^\n<]+)/i) ||
    html.match(/<h1[^>]*>([^<]+)<\/h1>/i);

  if (messageMatch) {
    message = messageMatch[1]
      .replace(/<[^>]+>/g, '')
      .trim()
      .substring(0, 200);
  }

  const frameMatch = html.match(
    /<pre[^>]*class="[^"]*frame[^"]*"[^>]*>([\s\S]*?)<\/pre>/i
  );
  if (frameMatch) {
    frame = frameMatch[1].replace(/<[^>]+>/g, '').trim();
  }

  return { message, frame };
}

export function htmlValidator() {
  return {
    name: 'html-validator',
    enforce: 'pre',

    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        const url = req.url || '';
        const isHtmlRequest =
          url === '/' ||
          url.endsWith('.html') ||
          (url.includes('.html?') && !url.startsWith('/@')) ||
          (!url.includes('.') &&
            !url.startsWith('/@') &&
            !url.startsWith('/__') &&
            !url.startsWith('/node_modules'));

        if (!isHtmlRequest) {
          return next();
        }

        const originalEnd = res.end.bind(res);
        const originalSetHeader = res.setHeader.bind(res);
        const chunks = [];

        res.write = function (chunk, encoding, callback) {
          if (chunk) {
            chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
          }
          if (typeof encoding === 'function') {
            encoding();
          } else if (typeof callback === 'function') {
            callback();
          }
          return true;
        };

        res.end = function (chunk, encoding, callback) {
          if (chunk) {
            chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
          }

          const body = Buffer.concat(chunks).toString('utf-8');

          const isViteErrorPage =
            (res.statusCode >= 400 &&
              body.includes('Error') &&
              (body.includes('vite-error-overlay') ||
                body.includes('Internal Server Error') ||
                body.includes('<pre'))) ||
            body.includes('Parse Error') ||
            body.includes('SyntaxError');

          if (isViteErrorPage) {
            const { message, frame } = extractErrorFromViteErrorPage(body);

            console.error(
              '[html-validator] Intercepted HTML parsing error:',
              message
            );

            const customErrorPage = generateErrorPage({
              message,
              frame,
              id: url,
            });

            res.statusCode = 500;
            if (!res.headersSent) {
              originalSetHeader('Content-Type', 'text/html');
              originalSetHeader(
                'Content-Length',
                Buffer.byteLength(customErrorPage)
              );
            }
            return originalEnd(customErrorPage, 'utf-8', callback);
          }

          if (body.length > 0 && !res.headersSent) {
            originalSetHeader('Content-Length', Buffer.byteLength(body));
          }
          return originalEnd(body, 'utf-8', callback);
        };

        next();
      });
    },
  };
}
