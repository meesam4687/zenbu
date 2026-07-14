import 'package:flutter_js/flutter_js.dart';

class JsVideosExtractors {
  final JavascriptRuntime runtime;
  JsVideosExtractors(this.runtime);

  void init() {
    runtime.onMessage('sibnetExtractor', (dynamic args) async => '[]');
    runtime.onMessage('myTvExtractor', (dynamic args) async => '[]');
    runtime.onMessage('okruExtractor', (dynamic args) async => '[]');
    runtime.onMessage('voeExtractor', (dynamic args) async => '[]');
    runtime.onMessage('vidBomExtractor', (dynamic args) async => '[]');
    runtime.onMessage('quarkVideosExtractor', (dynamic args) async => '[]');
    runtime.onMessage('ucVideosExtractor', (dynamic args) async => '[]');
    runtime.onMessage('quarkFilesExtractor', (dynamic args) async => []);
    runtime.onMessage('ucFilesExtractor', (dynamic args) async => []);
    runtime.onMessage('streamlareExtractor', (dynamic args) async => '[]');
    runtime.onMessage('sendVidExtractor', (dynamic args) async => '[]');
    runtime.onMessage('yourUploadExtractor', (dynamic args) async => '[]');
    runtime.onMessage('gogoCdnExtractor', (dynamic args) async => '[]');
    runtime.onMessage('doodExtractor', (dynamic args) async => '[]');
    runtime.onMessage('streamTapeExtractor', (dynamic args) async => '[]');
    runtime.onMessage('mp4UploadExtractor', (dynamic args) async => '[]');
    runtime.onMessage('streamWishExtractor', (dynamic args) async => '[]');
    runtime.onMessage('filemoonExtractor', (dynamic args) async => '[]');

    runtime.evaluate('''
      async function sibnetExtractor(url, prefix) {
        const result = await sendMessage("sibnetExtractor", JSON.stringify([url, prefix]));
        return JSON.parse(result);
      }
      async function myTvExtractor(url) {
        const result = await sendMessage("myTvExtractor", JSON.stringify([url]));
        return JSON.parse(result);
      }
      async function okruExtractor(url) {
        const result = await sendMessage("okruExtractor", JSON.stringify([url]));
        return JSON.parse(result);
      }
      async function voeExtractor(url, quality) {
        const result = await sendMessage("voeExtractor", JSON.stringify([url, quality]));
        return JSON.parse(result);
      }
      async function vidBomExtractor(url) {
        const result = await sendMessage("vidBomExtractor", JSON.stringify([url]));
        return JSON.parse(result);
      }
      async function streamlareExtractor(url, prefix, suffix) {
        const result = await sendMessage("streamlareExtractor", JSON.stringify([url, prefix, suffix]));
        return JSON.parse(result);
      }
      async function sendVidExtractor(url, headers, prefix) {
        const result = await sendMessage("sendVidExtractor", JSON.stringify([url, JSON.stringify(headers), prefix]));
        return JSON.parse(result);
      }
      async function yourUploadExtractor(url, headers, name, prefix) {
        const result = await sendMessage("yourUploadExtractor", JSON.stringify([url, JSON.stringify(headers), name, prefix]));
        return JSON.parse(result);
      }
      async function gogoCdnExtractor(url) {
        const result = await sendMessage("gogoCdnExtractor", JSON.stringify([url]));
        return JSON.parse(result);
      }
      async function doodExtractor(url, quality) {
        const result = await sendMessage("doodExtractor", JSON.stringify([url, quality]));
        return JSON.parse(result);
      }
      async function streamTapeExtractor(url, quality) {
        const result = await sendMessage("streamTapeExtractor", JSON.stringify([url, quality]));
        return JSON.parse(result);
      }
      async function mp4UploadExtractor(url, headers, prefix, suffix) {
        const result = await sendMessage("mp4UploadExtractor", JSON.stringify([url, JSON.stringify(headers), prefix, suffix]));
        return JSON.parse(result);
      }
      async function streamWishExtractor(url, prefix) {
        const result = await sendMessage("streamWishExtractor", JSON.stringify([url, prefix]));
        return JSON.parse(result);
      }
      async function filemoonExtractor(url, prefix, suffix) {
        const result = await sendMessage("filemoonExtractor", JSON.stringify([url, prefix, suffix]));
        return JSON.parse(result);
      }
      async function quarkVideosExtractor(url, cookie) {
        const result = await sendMessage("quarkVideosExtractor", JSON.stringify([url, cookie]));
        return JSON.parse(result);
      }
      async function ucVideosExtractor(url, cookie) {
        const result = await sendMessage("ucVideosExtractor", JSON.stringify([url, cookie]));
        return JSON.parse(result);
      }
      async function quarkFilesExtractor(urls, cookie) {
        return await sendMessage("quarkFilesExtractor", JSON.stringify([urls, cookie]));
      }
      async function ucFilesExtractor(urls, cookie) {
        return await sendMessage("ucFilesExtractor", JSON.stringify([urls, cookie]));
      }
    ''');
  }
}
