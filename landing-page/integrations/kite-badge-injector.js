export function kiteBadgeInjector(options = {}) {
  let isBuild = false;
  const isDisabled =
    options.disabled === true || process.env.VITE_DISABLE_KITE_BADGE === 'true';
  const appId = options.appId || '';

  const kiteIconSvg = `<svg width="20" height="20" viewBox="0 0 36 37" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
  <path d="M16.1125 18.2386C15.6193 21.2257 14.4972 25.1698 12.2792 27.3909C11.3745 28.2408 10.4019 28.5394 9.97343 28.5126C9.63405 28.4956 9.46773 28.1759 9.50531 27.9242C10.1515 21.0525 10.104 14.6401 9.50391 8.08358C9.48035 7.73678 9.76223 7.49486 10.0386 7.50524C10.3603 7.52263 14.5328 7.47187 14.7691 7.52558C15.1735 7.62557 15.1952 8.00533 15.1764 8.36322C15.1764 10.179 15.2876 10.1229 14.6808 10.7095C14.2793 11.111 13.6359 11.7487 13.2488 12.137C12.7351 12.5918 13.0289 12.9929 13.3749 13.5066C15.9881 17.4189 16.2488 17.5989 16.1126 18.2385L16.1125 18.2386Z" fill="#FF6D2D"/>
  <path d="M26.6218 27.7324C25.4614 25.8473 22.7405 21.5057 21.7432 19.8728C21.6479 19.7018 21.7022 19.5115 21.7908 19.4092C22.2219 18.8618 26.2758 13.6262 26.3072 13.5852C26.5926 13.1565 26.2916 12.6633 25.6711 12.735C21.3453 12.7375 21.3696 12.7111 21.1891 12.7859C20.8267 12.8964 20.8866 12.9081 18.172 16.9718C17.9134 17.3331 17.6607 17.7563 17.7632 18.217C18.3128 21.5444 20.1687 28.6515 24.4202 28.5119C24.9047 28.4999 25.821 28.5276 26.2159 28.5051C26.5385 28.472 26.7983 28.1217 26.6218 27.7324Z" fill="#FF6D2D"/>
</svg>`;

  const badgeCss = `
<style id="kite-badge-style">
  #kite-badge {
    position: fixed;
    bottom: calc(16px + env(safe-area-inset-bottom, 0px));
    right: calc(16px + env(safe-area-inset-right, 0px));
    z-index: 2147483647;
    display: flex;
    align-items: center;
    padding: 4px;
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    padding-right: 8px;
    transition: padding 0.2s ease;
  }
  #kite-badge:hover {
    padding-right: 4px;
  }
  #kite-badge a {
    display: inline-flex;
    align-items: center;
    gap: 2px;
    text-decoration: none;
    color: #374151;
    font-size: 13px;
    font-weight: 500;
    line-height: 1;
    outline: none;
  }
  #kite-badge a:focus-visible {
    text-decoration: underline;
  }
  #kite-badge-dismiss {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 0;
    height: 20px;
    padding: 0;
    overflow: hidden;
    margin-left: 0;
    background: transparent;
    border: none;
    border-radius: 4px;
    color: #9ca3af;
    cursor: pointer;
    opacity: 0;
    pointer-events: none;
    transition: width 0.2s ease, margin-left 0.2s ease, opacity 0.2s ease, color 0.2s ease, background-color 0.2s ease;
  }
  #kite-badge:hover #kite-badge-dismiss,
  #kite-badge:focus-within #kite-badge-dismiss {
    opacity: 1;
    pointer-events: auto;
    width: 20px;
    margin-left: 2px;
  }
  #kite-badge-dismiss:hover {
    color: #374151;
    background-color: #f3f4f6;
  }
  #kite-badge-dismiss:focus-visible {
    outline: none;
    box-shadow: 0 0 0 2px rgba(59,130,246,0.3);
    color: #374151;
  }
  @media (prefers-reduced-motion: reduce) {
    #kite-badge-dismiss {
      transition: none;
    }
  }
</style>`;

  const dismissIconSvg = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
    <path d="M18 6L6 18M6 6l12 12"/>
  </svg>`;

  const utmParams = new URLSearchParams({
    utm_source: 'app_badge',
    utm_medium: 'referral',
    utm_campaign: 'built_with_kite',
    ...(appId && { utm_content: appId }),
  });
  const badgeUrl = `https://kite.ai?${utmParams.toString()}`;

  const badgeHtml = `
<!-- Built with Kite Badge -->
<div id="kite-badge">
  <a href="${badgeUrl}" target="_blank" rel="noopener noreferrer" aria-label="Built with Kite - Visit kite.ai">
    ${kiteIconSvg}
    <span>Built with Kite</span>
  </a>
  <button id="kite-badge-dismiss" type="button" aria-label="Dismiss badge">
    ${dismissIconSvg}
  </button>
</div>
<script>
  document.getElementById('kite-badge-dismiss').onclick = function() {
    document.getElementById('kite-badge').style.display = 'none';
  };
</script>`;

  return {
    name: 'kite-badge-injector',

    configResolved(config) {
      isBuild = config.command === 'build';
      if (isBuild) {
        if (isDisabled) {
          console.log('⚠ Kite badge disabled via configuration');
        } else {
          console.log('✓ Kite badge enabled (production build)');
        }
      }
    },

    transformIndexHtml(html) {
      if (!isBuild) {
        return html;
      }

      if (isDisabled) {
        return html;
      }

      if (html.includes('id="kite-badge"')) {
        return html;
      }

      let result = html;

      const headCloseIndex = result.toLowerCase().indexOf('</head>');
      if (headCloseIndex !== -1) {
        result =
          result.slice(0, headCloseIndex) +
          `  ${badgeCss}\n` +
          result.slice(headCloseIndex);
      }

      const bodyCloseIndex = result.toLowerCase().indexOf('</body>');
      if (bodyCloseIndex !== -1) {
        result =
          result.slice(0, bodyCloseIndex) +
          `  ${badgeHtml}\n` +
          result.slice(bodyCloseIndex);
      } else {
        console.warn(
          '⚠ No </body> tag found - appending badge to end of HTML'
        );
        result = result + badgeHtml;
      }

      return result;
    },
  };
}
