import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
                          if (mounted) Navigator.of(context).pop();
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
            Tab(icon: Icon(Icons.extension), text: 'Extensions'),
            Tab(icon: Icon(Icons.cloud_queue), text: 'Repositories'),
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

    return RefreshIndicator(
      onRefresh: _loadExtensions,
      child: ListView.builder(
        itemCount: _allExtensions.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final ext = _allExtensions[index];
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
                child: const Icon(
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
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      Text(
                        'v${ext.version}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (isInst && !needsUpdate) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Installed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
