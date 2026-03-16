export function runtimeErrorCapturePlugin(options = {}) {
  const { isDev = true } = options;

  return {
    name: 'runtime-error-capture',
    enforce: 'pre',

    transformIndexHtml() {
      const scriptContent = isDev
        ? getDevelopmentScript()
        : getProductionScript();

      return [
        {
          tag: 'script',
          injectTo: 'head-prepend',
          children: scriptContent,
        },
      ];
    },
  };
}

function getDevelopmentScript() {
  return `
    window.__errorQueue = [];
    window.__errorOverlayReady = false;

    window.addEventListener('error', function(event) {
      var errorData = {
        type: 'error',
        message: event.message || (event.error && event.error.message) || 'Unknown error',
        stack: event.error && event.error.stack,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno
      };

      if (window.__errorOverlayReady && window.__showAppError) {
        window.__showAppError(errorData);
      } else {
        window.__errorQueue.push(errorData);
      }
    });

    window.addEventListener('unhandledrejection', function(event) {
      var reason = event.reason;
      var errorData = {
        type: 'unhandledrejection',
        message: (reason && reason.message) || String(reason) || 'Unhandled Promise Rejection',
        stack: reason && reason.stack
      };

      if (window.__errorOverlayReady && window.__showAppError) {
        window.__showAppError(errorData);
      } else {
        window.__errorQueue.push(errorData);
      }
    });
  `;
}

function getProductionScript() {
  return `
    (function() {
      var errorQueue = [];
      var pirschReady = false;
      var maxErrors = 5;
      var errorCount = 0;

      function reportToPirsch(errorData) {
        if (errorCount >= maxErrors) return;
        errorCount++;

        var location = errorData.filename || '';
        if (errorData.lineno) {
          location += ':' + errorData.lineno;
          if (errorData.colno) {
            location += ':' + errorData.colno;
          }
        }

        var stack = errorData.stack || '';
        if (stack.length > 1500) {
          stack = stack.substring(0, 1500) + '... (truncated)';
        }

        try {
          pirsch('Runtime Error', {
            meta: {
              type: errorData.type || 'error',
              message: (errorData.message || 'Unknown error').substring(0, 500),
              location: location.substring(0, 500),
              stack: stack,
              url: window.location.href.substring(0, 500)
            },
            non_interactive: true
          });
        } catch (e) {
          console.error('[Runtime Error]', errorData.message);
        }
      }

      function flushQueue() {
        while (errorQueue.length > 0) {
          reportToPirsch(errorQueue.shift());
        }
      }

      function handleError(errorData) {
        if (typeof pirsch === 'function') {
          pirschReady = true;
          reportToPirsch(errorData);
        } else {
          errorQueue.push(errorData);
        }
      }

      window.addEventListener('error', function(event) {
        handleError({
          type: 'error',
          message: event.message || (event.error && event.error.message) || 'Unknown error',
          stack: event.error && event.error.stack,
          filename: event.filename,
          lineno: event.lineno,
          colno: event.colno
        });
      });

      window.addEventListener('unhandledrejection', function(event) {
        var reason = event.reason;
        handleError({
          type: 'unhandledrejection',
          message: (reason && reason.message) || String(reason) || 'Unhandled Promise Rejection',
          stack: reason && reason.stack
        });
      });

      var checkCount = 0;
      var checkInterval = setInterval(function() {
        checkCount++;
        if (typeof pirsch === 'function') {
          pirschReady = true;
          flushQueue();
          clearInterval(checkInterval);
        } else if (checkCount >= 20) {
          clearInterval(checkInterval);
        }
      }, 500);

      document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
          if (typeof pirsch === 'function') {
            pirschReady = true;
            flushQueue();
          }
        }, 500);
      });
    })();
  `;
}
