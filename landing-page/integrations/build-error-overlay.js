import { ERROR_STYLES, ERROR_CONTAINER_HTML } from './error-page-generator.js';

export function buildErrorOverlayPlugin() {
  return {
    name: 'build-error-overlay',
    enforce: 'pre',

    transformIndexHtml() {
      return [
        {
          tag: 'style',
          injectTo: 'head',
          children: ERROR_STYLES,
        },
        {
          tag: 'div',
          injectTo: 'body-prepend',
          children: ERROR_CONTAINER_HTML.trim(),
        },
        {
          tag: 'script',
          injectTo: 'head',
          attrs: { type: 'module' },
          children: `
            const overlay = document.getElementById('custom-vite-error-overlay');
            const debugButton = document.getElementById('debug-button');

            function showError(payload) {
              const err = payload.err || payload.error || payload;

              const message = err.message || err.toString();
              let location = '';

              if (err.loc) {
                location = \`\${err.loc.file}:\${err.loc.line}:\${err.loc.column}\`;
              } else if (err.id) {
                location = err.id;
              }

              const frameContent = err.frame || err.stack;

              overlay.classList.add('visible');

              const errorDetails = {
                message: message,
                location: location,
                frame: err.frame || '',
                stack: err.stack || '',
                timestamp: new Date().toISOString()
              };

              debugButton.addEventListener('click', () => {

                window.parent.postMessage({
                  type: 'app-error-debug',
                  payload: {
                    message: errorDetails.message,
                    location: errorDetails.location,
                    frame: errorDetails.frame
                  }
                }, window.location.origin);

                console.log('Debug message sent to parent window');
              });

              window.parent.postMessage({
                type: 'app-runtime-error',
                payload: errorDetails
              }, window.location.origin);

              fetch('/__error-log', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(errorDetails)
              }).catch(() => {
              });
            }



            function handleViteOverlay(viteOverlay) {
              console.log('Vite overlay detected, extracting error...');
              const message = viteOverlay.shadowRoot?.querySelector('.message')?.textContent ||
                              viteOverlay.shadowRoot?.querySelector('.message-body')?.textContent;
              const file = viteOverlay.shadowRoot?.querySelector('.file')?.textContent;
              const frame = viteOverlay.shadowRoot?.querySelector('.frame')?.textContent;

              if (message) {
                showError({
                  err: {
                    message: message,
                    id: file,
                    frame: frame
                  }
                });
              }

              viteOverlay.remove();
            }

            const existingOverlay = document.querySelector('vite-error-overlay');
            if (existingOverlay) {
              handleViteOverlay(existingOverlay);
            }

            const observer = new MutationObserver(() => {
              const viteOverlay = document.querySelector('vite-error-overlay');
              if (viteOverlay) {
                handleViteOverlay(viteOverlay);
              }
            });

            observer.observe(document.body, { childList: true, subtree: true });

            window.__showAppError = (errorData) => {
              let location = errorData.filename || '';
              if (errorData.lineno) {
                location += ':' + errorData.lineno;
                if (errorData.colno) {
                  location += ':' + errorData.colno;
                }
              }

              showError({
                err: {
                  message: errorData.message || 'Unknown error',
                  stack: errorData.stack,
                  id: location || undefined
                }
              });
            };

            if (window.__errorQueue && window.__errorQueue.length > 0) {
              window.__showAppError(window.__errorQueue[0]);
            }

            window.__errorOverlayReady = true;

          `,
        },
      ];
    },
  };
}
