// Adds a copy button to every code block on the page.
//
// Pandoc renders a fenced code block as <pre><code>...</code></pre> (inside a
// div.sourceCode when it is highlighted), and session.lua renders a terminal
// session as <pre class="session"> with the typed lines in <b>. A code block
// copies its whole text. A session copies only the typed lines, without the
// "$ " prompt, so that the result can be pasted straight into a terminal.
(function () {
  'use strict';

  var COPY_ICON =
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" ' +
    'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
    'stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" ' +
    'rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';

  function sessionCommands(pre) {
    var lines = pre.textContent.split('\n');
    var commands = [];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf('$ ') === 0) {
        commands.push(lines[i].slice(2));
      }
    }
    return commands.join('\n');
  }

  function textOf(pre) {
    if (pre.classList.contains('session')) {
      return sessionCommands(pre);
    }
    var code = pre.querySelector('code');
    return (code || pre).textContent.replace(/\n$/, '');
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    return new Promise(function (resolve, reject) {
      var area = document.createElement('textarea');
      area.value = text;
      area.setAttribute('readonly', '');
      area.style.position = 'fixed';
      area.style.top = '-1000px';
      document.body.appendChild(area);
      area.select();
      try {
        document.execCommand('copy') ? resolve() : reject(new Error('copy failed'));
      } catch (err) {
        reject(err);
      }
      document.body.removeChild(area);
    });
  }

  function addButton(pre) {
    var text = textOf(pre);
    if (!text) { return; }

    var isSession = pre.classList.contains('session');
    var label = isSession ? 'Copy commands' : 'Copy';

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'copy-code-button';
    button.title = isSession ? 'Copy the commands without the $ prompt' : 'Copy to clipboard';
    button.setAttribute('aria-label', label);
    button.innerHTML = COPY_ICON + '<span>' + label + '</span>';

    button.addEventListener('click', function () {
      copyText(text).then(function () {
        button.classList.add('copied');
        button.querySelector('span').textContent = 'Copied!';
        setTimeout(function () {
          button.classList.remove('copied');
          button.querySelector('span').textContent = label;
        }, 1500);
      }, function () {
        button.querySelector('span').textContent = 'Press Ctrl+C';
        setTimeout(function () {
          button.querySelector('span').textContent = label;
        }, 1500);
      });
    });

    var wrapper = document.createElement('div');
    wrapper.className = 'copy-code-wrapper';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);
    wrapper.appendChild(button);
  }

  function init() {
    var blocks = document.querySelectorAll('pre');
    for (var i = 0; i < blocks.length; i++) {
      // Skip a pre that sits inside another pre and the table of contents.
      if (blocks[i].closest('pre pre, #TOC')) { continue; }
      // Skip a block fenced as {.lang .nocopy}: pandoc puts the class on the pre.
      if (blocks[i].classList.contains('nocopy')) { continue; }
      addButton(blocks[i]);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
