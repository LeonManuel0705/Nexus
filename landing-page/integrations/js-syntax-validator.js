import * as acorn from 'acorn';

export function jsSyntaxValidator(options = {}) {
  const { failOnError = true, ecmaVersion = 'latest' } = options;

  let isBuild = false;

  return {
    name: 'js-syntax-validator',

    config(_config, { command }) {
      isBuild = command === 'build';
    },

    transformIndexHtml: {
      order: 'pre',
      handler(html, ctx) {
        if (!isBuild) {
          return;
        }

        const filename = ctx.filename || 'index.html';

        try {
          validateScriptBlocks(html, filename, { failOnError, ecmaVersion });
        } catch (error) {
          throw error;
        }

        return;
      },
    },
  };
}

function validateScriptBlocks(html, filename, options) {
  const { failOnError, ecmaVersion } = options;

  const htmlLines = html.split('\n');

  const scriptBlockRegex = /<script([^>]*)>([\s\S]*?)<\/script>/gi;

  let match;
  const errors = [];

  while ((match = scriptBlockRegex.exec(html)) !== null) {
    const attributes = match[1];
    const content = match[2];

    const contentStartPos = match.index + match[0].indexOf('>') + 1;
    const beforeContent = html.substring(0, contentStartPos);
    const contentStartLine = (beforeContent.match(/\n/g) || []).length + 1;

    const hasExternalSrc = /src\s*=/.test(attributes);
    const typeMatch = attributes.match(/type\s*=\s*["']([^"']+)["']/);
    const type = typeMatch ? typeMatch[1] : 'text/javascript';
    const idMatch = attributes.match(/id\s*=\s*["']([^"']+)["']/);
    const scriptId = idMatch ? idMatch[1] : null;

    if (hasExternalSrc) {
      continue;
    }

    if (!content.trim()) {
      continue;
    }

    try {
      if (
        type === 'module' ||
        type === 'text/javascript' ||
        type === '' ||
        !typeMatch
      ) {
        const sourceType = type === 'module' ? 'module' : 'script';

        acorn.parse(content, {
          ecmaVersion: ecmaVersion,
          sourceType: sourceType,
          locations: true,
        });
      }
    } catch (error) {
      const errorLineInScript = error.loc ? error.loc.line : 1;
      const actualLineInHtml = contentStartLine + errorLineInScript - 1;
      const column = error.loc ? error.loc.column : 0;

      errors.push({
        line: actualLineInHtml,
        column: column,
        message: error.message,
        scriptId: scriptId,
        scriptType: type,
        htmlLines: htmlLines,
      });
    }
  }

  if (errors.length > 0) {
    const errorCount = errors.length;
    const plural = errorCount === 1 ? '' : 's';

    const errorMessages = errors
      .map(err => {
        const scriptInfo = err.scriptId
          ? ` <script id="${err.scriptId}">`
          : ' <script>';

        const lineNum = err.line;
        const contextLines = 3;
        const startLine = Math.max(1, lineNum - contextLines);
        const endLine = Math.min(err.htmlLines.length, lineNum + contextLines);

        const codeSnippet = [];
        for (let i = startLine; i <= endLine; i++) {
          const lineContent = err.htmlLines[i - 1];
          const marker = i === lineNum ? '>' : ' ';
          const lineNumPadded = String(i).padStart(4, ' ');
          codeSnippet.push(`   ${marker} ${lineNumPadded} | ${lineContent}`);
        }

        return [
          `  ❌ ${filename}:${err.line}:${err.column}`,
          `     ${err.message}`,
          `     In${scriptInfo}`,
          '',
          codeSnippet.join('\n'),
          '',
        ].join('\n');
      })
      .join('\n');

    const fullError = [
      '',
      '═'.repeat(80),
      `  Syntax Error${plural} in HTML Script Blocks (${errorCount} found)`,
      '═'.repeat(80),
      '',
      errorMessages,
      '═'.repeat(80),
      '',
    ].join('\n');

    if (failOnError) {
      throw new Error(fullError);
    } else {
      console.warn(fullError);
    }
  }
}
