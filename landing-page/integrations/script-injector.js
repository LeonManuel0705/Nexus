
const SCRIPT_INJECTOR_CDN_URL =
  'https://assets.appsmith.com/kite_script_injector_v020.js';
const SCRIPT_INJECTOR_TAG = `<script src="${SCRIPT_INJECTOR_CDN_URL}"></script>`;

export function scriptInjector() {
  let isDev = false;

  return {
    name: 'script-injector',

    configResolved(config) {
      isDev = config.command === 'serve';
    },

    transformIndexHtml(html) {
      if (!isDev) {
        return html.replace(SCRIPT_INJECTOR_TAG, '');
      }

      if (html.includes(SCRIPT_INJECTOR_TAG)) {
        return;
      }

      return [
        {
          tag: 'script',
          attrs: { src: SCRIPT_INJECTOR_CDN_URL },
          injectTo: 'body',
        },
      ];
    },

    configureServer() {
      console.log('✓ script-injector enabled (development mode)');
    },

    buildStart() {
      if (!isDev) {
        console.log('✓ script-injector-remover enabled (production build)');
      }
    },
  };
}
