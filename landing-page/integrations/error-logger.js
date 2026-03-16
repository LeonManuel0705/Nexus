import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function errorLoggerPlugin() {
  const logFilePath = path.resolve(
    fileURLToPath(new URL('..', import.meta.url)),
    'error.log'
  );

  return {
    name: 'error-logger',
    configureServer(server) {
      server.middlewares.use('/__error-log', (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405;
          res.end('Method not allowed');
          return;
        }

        let body = '';
        let bodySize = 0;
        req.on('data', chunk => {
          bodySize += chunk.length;
          if (bodySize > 65536) { // 64KB limit
            res.statusCode = 413;
            res.end('Payload too large');
            req.destroy();
            return;
          }
          body += chunk.toString();
        });

        req.on('end', () => {
          try {
            const errorData = JSON.parse(body);
            const logEntry = [
              `[${errorData.timestamp}]`,
              `Location: ${errorData.location || 'unknown'}`,
              `Message: ${errorData.message}`,
              errorData.frame ? `Frame:\n${errorData.frame}` : '',
              errorData.stack ? `Stack:\n${errorData.stack}` : '',
              '---\n',
            ]
              .filter(Boolean)
              .join('\n');

            fs.appendFileSync(logFilePath, logEntry);
            res.statusCode = 200;
            res.end('OK');
          } catch {
            res.statusCode = 400;
            res.end('Invalid JSON');
          }
        });
      });
    },
  };
}
