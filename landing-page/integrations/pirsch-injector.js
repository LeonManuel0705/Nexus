
export function pirschInjector(pirschToken) {
  let isBuild = false;

  return {
    name: 'pirsch-injector',

    configResolved(config) {
      isBuild = config.command === 'build';
      if (isBuild) {
        if (pirschToken) {
          console.log('✓ Pirsch analytics enabled (production build)');
        } else {
          console.log('⚠ Pirsch analytics disabled (no token configured)');
        }
      }
    },

    transformIndexHtml(html) {
      if (!isBuild) {
        return html;
      }

      if (!pirschToken) {
        console.log('⚠ Pirsch token not found - skipping analytics injection');
        return html;
      }

      if (!/^[a-zA-Z0-9-]+$/.test(pirschToken)) {
        console.error(
          '⚠ Invalid Pirsch token format - skipping analytics injection'
        );
        return html;
      }

      const pirschScript = `<script defer src="https://api.pirsch.io/pa.js" id="pianjs" data-code="${pirschToken}"></script>`;

      let transformedHtml = html;

      const headCloseIndex = html.toLowerCase().indexOf('</head>');
      if (headCloseIndex !== -1) {
        transformedHtml =
          html.slice(0, headCloseIndex) +
          `  ${pirschScript}\n` +
          html.slice(headCloseIndex);
      }

      return transformedHtml;
    },
  };
}
