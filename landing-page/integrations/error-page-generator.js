
export const ERROR_STYLES = `
  .custom-vite-error-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 99999;
    background: #fff;
    display: none;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    overflow-y: auto;
  }

  .custom-vite-error-overlay.visible {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .custom-error-container {
    display: flex;
    width: 343px;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    text-align: center;
  }

  .custom-error-icon {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .custom-error-icon svg {
    width: 24px;
    height: 24px;
    color: #DC2626;
  }

  .custom-error-header h1 {
    color: #171717;
    text-align: center;
    font-size: 16px;
    font-style: normal;
    font-weight: 500;
    line-height: 150%;
  }

  .custom-error-subtitle {
    color: #737373;
    text-align: center;

    font-size: 14px;
    font-style: normal;
    font-weight: 400;
    line-height: 150%;
    letter-spacing: 0.07px;
  }

  .custom-debug-button {
    display: flex;
    width: 165.5px;
    min-height: 36px;
    padding: 8px 16px;
    justify-content: center;
    align-items: center;
    gap: 8px;
    border-radius: 8px;
    background: #E15615;
    color: #fff;
    border: none;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
  }

  .custom-debug-button:hover {
    background: #c94a12;
  }

  vite-error-overlay {
    display: none !important;
  }
`;

export const ERROR_CONTAINER_HTML = `
  <div id="custom-vite-error-overlay" class="custom-vite-error-overlay">
    <div class="custom-error-container">
      <div class="custom-error-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M12 20V11M12 20C13.5913 20 15.1174 19.3679 16.2426 18.2426C17.3679 17.1174 18 15.5913 18 14V11C18 9.93913 17.5786 8.92172 16.8284 8.17157C16.0783 7.42143 15.0609 7 14 7H10C8.93913 7 7.92172 7.42143 7.17157 8.17157C6.42143 8.92172 6 9.93913 6 11V14C6 15.5913 6.63214 17.1174 7.75736 18.2426C8.88258 19.3679 10.4087 20 12 20ZM14.12 3.88L16 2M21 21C21.0012 19.9712 20.6059 18.9816 19.8964 18.2367C19.1868 17.4918 18.2176 17.0489 17.19 17M21 5C20.9989 5.98215 20.6364 6.92956 19.9818 7.66169C19.3271 8.39383 18.4259 8.85951 17.45 8.97M22 13H18M3 21C2.99884 19.9712 3.39409 18.9816 4.10362 18.2367C4.81315 17.4918 5.78241 17.0489 6.81 17M3 5C3.00113 5.98215 3.36357 6.92956 4.01825 7.66169C4.67293 8.39383 5.57408 8.85951 6.55 8.97M6 13H2M8 2L9.88 3.88M9 7.13V6C9 5.20435 9.31607 4.44129 9.87868 3.87868C10.4413 3.31607 11.2044 3 12 3C12.7956 3 13.5587 3.31607 14.1213 3.87868C14.6839 4.44129 15 5.20435 15 6V7.13" stroke="#475569" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>

      <div class="custom-error-header">
        <h1>Whoops. Quick fix needed.</h1>
        <p class="custom-error-subtitle">Your site is safe and saved. We ran into a small issue during the update. Click below to fix it.</p>
      </div>

      <button class="custom-debug-button" id="debug-button" title="Send error to AI for debugging">
        Fix with AI
      </button>
    </div>
  </div>
`;

export function generateErrorPage(error) {
  const message = error.message || 'HTML parsing error';
  const location = error.loc
    ? `${error.loc.file}:${error.loc.line}:${error.loc.column}`
    : error.id || '';
  const frame = error.frame || '';
  const stack = error.stack || '';

  const errorDetails = JSON.stringify({
    message,
    location,
    frame,
    stack,
    timestamp: new Date().toISOString(),
  }).replace(/<\//g, '<\\/');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Error</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: #fff;
    }
    ${ERROR_STYLES}
  </style>
</head>
<body>
  ${ERROR_CONTAINER_HTML.trim()}

  <script>
    const errorDetails = ${errorDetails};

    window.parent.postMessage({
      type: 'app-runtime-error',
      payload: errorDetails
    }, window.location.origin);

    document.getElementById('debug-button').addEventListener('click', () => {
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

    fetch('/__error-log', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(errorDetails)
    }).catch(() => {});
  </script>
</body>
</html>`;
}
