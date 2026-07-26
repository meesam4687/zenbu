import 'package:flutter_js/flutter_js.dart';

class JsHtmlParser {
  late JavascriptRuntime runtime;
  JsHtmlParser(this.runtime);

  void init() {
    runtime.evaluate('''
class Parser {
    constructor(options = {}) {
        this.options = options;
        this.buffer = '';
    }

    isVoidElement(name) {
      return [
        "area",
        "base",
        "basefont",
        "br",
        "col",
        "command",
        "embed",
        "frame",
        "hr",
        "img",
        "input",
        "isindex",
        "keygen",
        "link",
        "meta",
        "param",
        "source",
        "track",
        "wbr",
      ].includes(name);
    }

    write(html) {
        this.buffer += html;
        let i = 0;
        let textStart = 0;
        const len = this.buffer.length;
        let insideQuote = null;

        while (i < len) {
            const ch = this.buffer[i];

            if ((ch === '"' || ch === "'")) {
                if (insideQuote === ch) {
                    insideQuote = null;
                } else if (insideQuote === null) {
                    insideQuote = ch;
                }
                i++;
                continue;
            }

            if (ch === '<' && insideQuote === null) {
                if (i > textStart && this.options.ontext) {
                    const text = this.buffer.slice(textStart, i);
                    this.options.ontext(text);
                }

                const tagStart = i;
                i++;

                const isClosing = this.buffer[i] === '/';
                if (isClosing) i++;

                const nameStart = i;
                while (i < len && /[a-zA-Z0-9:-]/.test(this.buffer[i])) i++;
                const nameEnd = i;
                const tagName = this.buffer.slice(nameStart, nameEnd);

                if (isClosing) {
                    if (this.options.onclosetag) {
                        this.options.onclosetag(tagName);
                    }
                } else {
                    if (this.options.onopentagname) {
                        this.options.onopentagname(tagName);
                    }
                }

                let attrs = {};
                while (i < len && this.buffer[i] !== '>') {
                    i++;
                }

                if (i < len && this.buffer[i] === '>') {
                    i++;
                    textStart = i;
                }
            } else {
                i++;
            }
        }

        if (textStart < len && this.options.ontext) {
            this.options.ontext(this.buffer.slice(textStart));
        }
    }

    end() {
        this.buffer = '';
    }
}
''');
  }
}
