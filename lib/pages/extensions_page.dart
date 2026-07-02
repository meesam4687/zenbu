import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/components/global/custom_image.dart';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ExtRepo> _repos = [];
  List<ExtSource> _allExtensions = [];
  List<ExtSource> _installedExtensions = [];
  bool _isLoadingRepos = false;
  bool _isLoadingExtensions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRepos();
    _loadExtensions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRepos() async {
    setState(() => _isLoadingRepos = true);
    try {
      final repos = await RepoService.getRepos();
      setState(() {
        _repos = repos;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading repos: $e');
    } finally {
      setState(() => _isLoadingRepos = false);
    }
  }

  Future<void> _loadExtensions() async {
    setState(() => _isLoadingExtensions = true);
    try {
      final installed = await RepoService.getInstalledExtensions();
      final all = await RepoService.fetchAllExtensions();
      setState(() {
        _installedExtensions = installed;
        _allExtensions = all;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading extensions: $e');
    } finally {
      setState(() => _isLoadingExtensions = false);
    }
  }

  Future<void> _addRepository(String url) async {
    try {
      await RepoService.addRepo(url);
      Fluttertoast.showToast(msg: 'Repository added successfully!');
      _loadRepos();
      _loadExtensions();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to add repository: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _deleteRepository(String url) async {
    try {
      await RepoService.deleteRepo(url);
      Fluttertoast.showToast(msg: 'Repository removed');
      _loadRepos();
      _loadExtensions();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error removing repository: $e');
    }
  }

  Future<void> _installExtension(ExtSource ext) async {
    try {
      Fluttertoast.showToast(msg: 'Installing ${ext.name}...');
      await RepoService.installExtension(ext);
      Fluttertoast.showToast(msg: '${ext.name} installed successfully!');
      _loadExtensions();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to install ${ext.name}: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _uninstallExtension(ExtSource ext) async {
    try {
      await RepoService.uninstallExtension(ext);
      Fluttertoast.showToast(msg: '${ext.name} uninstalled');
      _loadExtensions();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to uninstall ${ext.name}: $e');
    }
  }

  Future<void> _showExtensionSettings(ExtSource ext) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExtensionSettingsSheet(ext: ext),
    );
  }

  void _showAddRepoDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool isAdding = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Extension Repo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the JSON URL of the repository (e.g. Mangayomi compatible repositories)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Repository URL',
                      hintText: 'https://example.com/index.json',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          final url = controller.text.trim();
                          if (url.isEmpty) {
                            Fluttertoast.showToast(msg: 'URL cannot be empty');
                            return;
                          }
                          setDialogState(() => isAdding = true);
                          await _addRepository(url);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensions Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Extensions'),
            Tab(text: 'Repositories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExtensionsTab(), _buildReposTab()],
      ),
    );
  }

  Widget _buildExtensionsTab() {
    if (_isLoadingExtensions) {
      return Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_allExtensions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No extensions available.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a repository URL in the next tab first!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final filteredExtensions = _allExtensions.where((ext) {
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return ext.name.toLowerCase().contains(query) ||
          ext.lang.toLowerCase().contains(query) ||
          (ext.isManga ? 'manga' : 'anime').contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search extensions...',
            elevation: const WidgetStatePropertyAll(1.0),
            backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onInverseSurface,
            ),
            leading: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.search),
            ),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                ),
            ],
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),
        Expanded(
          child: filteredExtensions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results for "$_searchQuery"',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try checking your spelling or search terms.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExtensions,
                  child: ListView.builder(
                    itemCount: filteredExtensions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final ext = filteredExtensions[index];
                      final isInst = _installedExtensions.any((e) => e.id == ext.id);
                      final localExt = isInst
                          ? _installedExtensions.firstWhere((e) => e.id == ext.id)
                          : null;
                      final needsUpdate =
                          isInst && localExt != null && localExt.version != ext.version;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ext.iconUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CustomImage(
                                      imageUrl: ext.iconUrl,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(8),
                                      errorWidget: const Icon(
                                        Icons.extension,
                                        color: Colors.blueGrey,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.extension,
                                    color: Colors.blueGrey,
                                    size: 28,
                                  ),
                          ),
                          title: Text(
                            ext.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ext.isManga
                                          ? Colors.green.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ext.isManga ? 'MANGA' : 'ANIME',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: ext.isManga
                                            ? Colors.green.shade900
                                            : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ext.lang.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  if (ext.isNsfw)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '18+',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    'v${ext.version}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (isInst && !needsUpdate)
                                    const Text(
                                      'Installed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isInst) ...[
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  tooltip: 'Settings',
                                  onPressed: () => _showExtensionSettings(ext),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (!isInst)
                                ElevatedButton.icon(
                                  onPressed: () => _installExtension(ext),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Install'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                )
                              else if (needsUpdate)
                                FilledButton.icon(
                                  onPressed: () => _installExtension(ext),
                                  icon: const Icon(Icons.update, size: 16),
                                  label: const Text('Update'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () => _uninstallExtension(ext),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Uninstall',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.red.shade200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReposTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRepoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Repository'),
      ),
      body: _isLoadingRepos
          ? Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : _repos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No repositories added.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click the + button to add a source repo!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _repos.length,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemBuilder: (context, index) {
                final repo = _repos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      repo.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          repo.jsonUrl,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Repository'),
                            content: Text(
                              'Are you sure you want to remove the repository "${repo.name}"? This will hide its extensions from the list.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteRepository(repo.jsonUrl);
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ExtensionSettingsSheet extends StatefulWidget {
  final ExtSource ext;

  const _ExtensionSettingsSheet({required this.ext});

  @override
  State<_ExtensionSettingsSheet> createState() =>
      _ExtensionSettingsSheetState();
}

class _ExtensionSettingsSheetState extends State<_ExtensionSettingsSheet> {
  List<dynamic> _preferences = [];
  Map<String, dynamic> _savedValues = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = 'ext_pref_${widget.ext.id}_';
      final saved = <String, dynamic>{};
      for (final key in keys) {
        if (key.startsWith(prefix)) {
          final prefKey = key.substring(prefix.length);
          final raw = prefs.getString(key);
          if (raw != null) {
            try {
              saved[prefKey] = json.decode(raw);
            } catch (_) {}
          }
        }
      }

      final definitions = await RepoService.getExtensionPreferences(widget.ext);

      setState(() {
        _preferences = definitions;
        _savedValues = saved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateValue(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = 'ext_pref_${widget.ext.id}_$key';
    await prefs.setString(prefKey, json.encode(value));
    setState(() {
      _savedValues[key] = value;
    });
  }

  dynamic _getCurrentValue(Map<String, dynamic> pref) {
    final key = pref['key'] as String;
    if (_savedValues.containsKey(key)) {
      return _savedValues[key];
    }
    if (pref['checkBoxPreference'] != null) {
      return pref['checkBoxPreference']['value'] ?? false;
    }
    if (pref['switchPreferenceCompat'] != null) {
      return pref['switchPreferenceCompat']['value'] ?? false;
    }
    if (pref['editTextPreference'] != null) {
      return pref['editTextPreference']['value'] ?? '';
    }
    if (pref['listPreference'] != null) {
      final lp = pref['listPreference'];
      final valueIndex = lp['valueIndex'] as int? ?? 0;
      final entryValues = List<String>.from(lp['entryValues'] ?? []);
      if (valueIndex >= 0 && valueIndex < entryValues.length) {
        return entryValues[valueIndex];
      }
      return '';
    }
    if (pref['multiSelectListPreference'] != null) {
      return List<String>.from(
        pref['multiSelectListPreference']['values'] ?? [],
      );
    }
    return null;
  }

  void _showTextDialog(String key, Map<String, dynamic> p, String currVal) {
    final controller = TextEditingController(text: currVal);
    final dialogTitle =
        p['dialogTitle'] as String? ?? p['title'] as String? ?? 'Edit Setting';
    final dialogMessage =
        p['dialogMessage'] as String? ?? p['summary'] as String? ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dialogMessage.isNotEmpty) ...[
              Text(
                dialogMessage,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _updateValue(key, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showListDialog(
    String key,
    String title,
    String summary,
    List<String> entries,
    List<String> entryValues,
    String currVal,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final val = entryValues[index];
              final label = entries[index];
              return RadioListTile<String>(
                title: Text(label),
                value: val,
                // ignore: deprecated_member_use
                groupValue: currVal,
                // ignore: deprecated_member_use
                onChanged: (newVal) {
                  if (newVal != null) {
                    _updateValue(key, newVal);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectDialog(
    String key,
    String title,
    List<String> entries,
    List<String> entryValues,
    List<String> currVals,
  ) {
    final selected = List<String>.from(currVals);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final val = entryValues[index];
                final label = entries[index];
                final isChecked = selected.contains(val);
                return CheckboxListTile(
                  title: Text(label),
                  value: isChecked,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selected.add(val);
                      } else {
                        selected.remove(val);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _updateValue(key, selected);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.ext.iconUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomImage(
                                imageUrl: widget.ext.iconUrl,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(8),
                                errorWidget: const Icon(
                                  Icons.extension,
                                  color: Colors.blueGrey,
                                  size: 28,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.extension,
                              color: Colors.blueGrey,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ext.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version ${widget.ext.version} • ${widget.ext.lang.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _buildBody(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: 16),
              Text('Reading settings...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load settings:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_preferences.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'This extension has no settings.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _preferences.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> pref = Map<String, dynamic>.from(
          _preferences[index],
        );
        final key = pref['key'] as String? ?? '';
        if (key.isEmpty) return const SizedBox.shrink();

        if (pref['checkBoxPreference'] != null ||
            pref['switchPreferenceCompat'] != null) {
          final isCompat = pref['switchPreferenceCompat'] != null;
          final p = isCompat
              ? pref['switchPreferenceCompat']
              : pref['checkBoxPreference'];
          final title = p['title'] as String? ?? '';
          final summary = p['summary'] as String? ?? '';
          final currValue = _getCurrentValue(pref) as bool? ?? false;
          return SwitchListTile.adaptive(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: summary.isNotEmpty ? Text(summary) : null,
            value: currValue,
            onChanged: (val) => _updateValue(key, val),
          );
        }

        if (pref['editTextPreference'] != null) {
          final p = pref['editTextPreference'];
          final title = p['title'] as String? ?? '';
          final summary = p['summary'] as String? ?? '';
          final currValue = _getCurrentValue(pref) as String? ?? '';
          return ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              currValue.isEmpty
                  ? (summary.isNotEmpty ? summary : 'Not configured')
                  : currValue,
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _showTextDialog(key, p, currValue),
          );
        }

        if (pref['listPreference'] != null) {
          final p = pref['listPreference'];
          final title = p['title'] as String? ?? '';
          final summary = p['summary'] as String? ?? '';
          final entries = List<String>.from(p['entries'] ?? []);
          final entryValues = List<String>.from(p['entryValues'] ?? []);
          final currValue = _getCurrentValue(pref) as String? ?? '';

          String displayVal = currValue;
          final idx = entryValues.indexOf(currValue);
          if (idx != -1 && idx < entries.length) {
            displayVal = entries[idx];
          }

          return ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              displayVal.isEmpty
                  ? (summary.isNotEmpty ? summary : 'Choose setting')
                  : displayVal,
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showListDialog(
              key,
              title,
              summary,
              entries,
              entryValues,
              currValue,
            ),
          );
        }

        if (pref['multiSelectListPreference'] != null) {
          final p = pref['multiSelectListPreference'];
          final title = p['title'] as String? ?? '';
          final summary = p['summary'] as String? ?? '';
          final entries = List<String>.from(p['entries'] ?? []);
          final entryValues = List<String>.from(p['entryValues'] ?? []);
          final currValues = List<String>.from(_getCurrentValue(pref) ?? []);

          final List<String> displayVals = [];
          for (final val in currValues) {
            final idx = entryValues.indexOf(val);
            if (idx != -1 && idx < entries.length) {
              displayVals.add(entries[idx]);
            } else {
              displayVals.add(val);
            }
          }
          final displayString = displayVals.isEmpty
              ? (summary.isNotEmpty ? summary : 'None selected')
              : displayVals.join(', ');

          return ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(displayString),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showMultiSelectDialog(
              key,
              title,
              entries,
              entryValues,
              currValues,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
