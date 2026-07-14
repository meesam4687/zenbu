import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_source.dart';

class JsPreferences {
  final JavascriptRuntime runtime;
  final Source source;
  JsPreferences(this.runtime, this.source);

  void init() {
    runtime.onMessage('save_pref', (dynamic args) async {
      try {
        final key = args[0] as String;
        final value = args[1];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ext_pref_${source.id}_$key', json.encode(value));
      } catch (_) {}
      return null;
    });

    runtime.onMessage('get', (dynamic args) async {
      try {
        final key = args[0] as String;
        final prefs = await SharedPreferences.getInstance();
        final rawVal = prefs.getString('ext_pref_${source.id}_$key');
        if (rawVal != null) {
          return json.decode(rawVal);
        }
      } catch (_) {}
      return null;
    });

    runtime.evaluate('''
      class SharedPreferences {
        get(key) {
          if (typeof _userPrefs !== 'undefined' && _userPrefs[key] !== undefined && _userPrefs[key] !== null) {
            return _userPrefs[key];
          }
          if (typeof extension !== 'undefined' && typeof extension.getSourcePreferences === 'function') {
            try {
              const prefs = extension.getSourcePreferences() || [];
              const p = prefs.find(x => x.key === key);
              if (p) {
                if (p.listPreference) return p.listPreference.entryValues[p.listPreference.valueIndex || 0];
                if (p.checkBoxPreference) return p.checkBoxPreference.value;
                if (p.switchPreferenceCompat) return p.switchPreferenceCompat.value;
                if (p.editTextPreference) return p.editTextPreference.value;
                if (p.multiSelectListPreference) return p.multiSelectListPreference.values;
              }
            } catch(e) {
              console.log("Error getting default pref: " + e);
            }
          }
          return null;
        }
        getString(key, defaultValue) {
          const val = this.get(key);
          return val !== null ? val : defaultValue;
        }
        setString(key, value) {
          if (typeof _userPrefs === 'undefined') _userPrefs = {};
          _userPrefs[key] = value;
          sendMessage('save_pref', JSON.stringify([key, value]));
          return true;
        }
        getBool(key, defaultValue) {
          const val = this.get(key);
          return val !== null ? (val === true || val === 'true') : defaultValue;
        }
        setBool(key, value) {
          return this.setString(key, value);
        }
        getInt(key, defaultValue) {
          const val = this.get(key);
          if (val !== null) {
            const parsed = parseInt(val);
            return isNaN(parsed) ? defaultValue : parsed;
          }
          return defaultValue;
        }
        setInt(key, value) {
          return this.setString(key, value);
        }
        getDouble(key, defaultValue) {
          const val = this.get(key);
          if (val !== null) {
            const parsed = parseFloat(val);
            return isNaN(parsed) ? defaultValue : parsed;
          }
          return defaultValue;
        }
        setDouble(key, value) {
          return this.setString(key, value);
        }
      }
    ''');
  }
}
