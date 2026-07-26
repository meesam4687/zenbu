import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';

class JsLibs {
  late JavascriptRuntime runtime;
  JsLibs(this.runtime);

  void init() {
    runtime.onMessage('log', (dynamic args) {
      if (kDebugMode) {
        print("[LNReader JS] ${args[0]}");
      }
      return null;
    });
    runtime.onMessage('urlencode', (dynamic args) {
      return Uri.encodeComponent(args[0]?.toString() ?? '');
    });
    runtime.onMessage('urldecode', (dynamic args) {
      return Uri.decodeComponent(args[0]?.toString() ?? '');
    });

    runtime.evaluate('''
console.log = function (message) {
    if (typeof message === "object") {
         message = JSON.stringify(message);
      }
    sendMessage("log", JSON.stringify([message ? message.toString() : ""]));
};
console.warn = function (message) {
    if (typeof message === "object") {
         message = JSON.stringify(message);
      }
    sendMessage("log", JSON.stringify([message ? message.toString() : ""]));
};
console.error = function (message) {
    if (typeof message === "object") {
         message = JSON.stringify(message);
      }
    sendMessage("log", JSON.stringify([message ? message.toString() : ""]));
};
String.prototype.substringAfter = function(pattern) {
    const startIndex = this.indexOf(pattern);
    if (startIndex === -1) return this.substring(0);

    const start = startIndex + pattern.length;
    return this.substring(start);
}

String.prototype.substringAfterLast = function(pattern) {
    return this.split(pattern).pop();
}

String.prototype.substringBefore = function(pattern) {
    const endIndex = this.indexOf(pattern);
    if (endIndex === -1) return this.substring(0);

    return this.substring(0, endIndex);
}

String.prototype.substringBeforeLast = function(pattern) {
    const endIndex = this.lastIndexOf(pattern);
    if (endIndex === -1) return this.substring(0);
    return this.substring(0, endIndex);
}

String.prototype.substringBetween = function(left, right) {
    let startIndex = 0;
    let index = this.indexOf(left, startIndex);
    if (index === -1) return "";
    let leftIndex = index + left.length;
    let rightIndex = this.indexOf(right, leftIndex);
    if (rightIndex === -1) return "";
    startIndex = rightIndex + right.length;
    return this.substring(leftIndex, rightIndex);
}

async function jsonStringify(fn) {
    return JSON.stringify(await fn());
}

const isUrlAbsolute = url => {
  if (url) {
    if (url.indexOf("//") === 0) {
      return true;
    }
    if (url.indexOf("://") === -1) {
      return false;
    }
    if (url.indexOf(".") === -1) {
      return false;
    }
    if (url.indexOf("/") === -1) {
      return false;
    }
    if (url.indexOf(":") > url.indexOf("/")) {
      return false;
    }
    return true;
  }
  return false;
};

const NovelStatus = {
  Unknown: "Unknown",
  Ongoing: "Ongoing",
  Completed: "Completed",
  Licensed: "Licensed",
  PublishingFinished: "Publishing Finished",
  Cancelled: "Cancelled",
  OnHiatus: "On Hiatus"
};

const FilterTypes = {
  TextInput: "TextInput",
  Picker: "Picker",
  Checkbox: "Checkbox",
  Switch: "Switch",
  ExcludableCheckbox: "ExcludableCheckbox"
};

const isPickerValue = val => typeof val === "string" || typeof val === "number";
const isCheckboxValue = val => Array.isArray(val);
const isSwitchValue = val => typeof val === "boolean";
const isTextValue = val => typeof val === "string";
const isXCheckboxValue = val => typeof val === "object";
''');
  }
}
