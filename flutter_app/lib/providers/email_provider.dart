import 'package:flutter/material.dart';
import '../models/email.dart';
import '../services/email_service.dart';
import '../services/connectivity_service.dart';

class EmailProvider extends ChangeNotifier {
  final EmailService _service = EmailService();
  final ConnectivityService _connectivity = ConnectivityService();

  List<EmailAccount> _accounts = [];
  List<EmailAccount> get accounts => _accounts;

  EmailAccount? _selectedAccount;
  EmailAccount? get selectedAccount => _selectedAccount;

  List<EmailFolder> _folders = [];
  List<EmailFolder> get folders => _folders;

  EmailFolder? _selectedFolder;
  EmailFolder? get selectedFolder => _selectedFolder;

  List<Email> _emails = [];
  List<Email> get emails => _emails;

  Email? _selectedEmail;
  Email? get selectedEmail => _selectedEmail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool get hasAccounts => _accounts.isNotEmpty;

  int get totalUnread {
    return _folders.fold(0, (sum, folder) => sum + folder.unreadCount);
  }

  EmailFolder? get inboxFolder {
    return _folders.where((f) => f.path == 'INBOX').firstOrNull;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _service.getAccounts();

      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.firstWhere(
          (a) => a.isDefault,
          orElse: () => _accounts.first,
        );

        await loadFolders();

        if (_folders.isNotEmpty) {
          _selectedFolder = inboxFolder ?? _folders.first;
          await loadEmails();
        }
      }
    } catch (e) {
      _error = 'Fehler beim Laden der E-Mail-Konten';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFolders() async {
    if (_selectedAccount == null) return;

    try {
      _folders = await _service.getFolders(_selectedAccount!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Fehler beim Laden der Ordner';
      notifyListeners();
    }
  }

  Future<void> loadEmails() async {
    if (_selectedAccount == null || _selectedFolder == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _emails = await _service.getEmails(
        accountId: _selectedAccount!.id,
        folderId: _selectedFolder!.id,
      );
      _error = null;
    } catch (e) {
      _error = 'Fehler beim Laden der E-Mails';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectAccount(EmailAccount account) async {
    _selectedAccount = account;
    _selectedFolder = null;
    _emails = [];
    _selectedEmail = null;
    notifyListeners();
    await loadFolders();
    if (_folders.isNotEmpty) {
      _selectedFolder = inboxFolder ?? _folders.first;
      await loadEmails();
    }
  }

  Future<void> selectFolder(EmailFolder folder) async {
    _selectedFolder = folder;
    _emails = [];
    _selectedEmail = null;
    notifyListeners();
    await loadEmails();
  }

  Future<void> selectEmail(Email email) async {
    _selectedEmail = email;
    notifyListeners();

    if (!email.isRead) {
      await markAsRead(email.id);
    }
  }

  void clearSelectedEmail() {
    _selectedEmail = null;
    notifyListeners();
  }

  Future<bool> addAccount({
    required String email,
    required String password,
    required String imapHost,
    required int imapPort,
    required String smtpHost,
    required int smtpPort,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final account = await _service.addImapAccount(
        email: email,
        password: password,
        imapHost: imapHost,
        imapPort: imapPort,
        smtpHost: smtpHost,
        smtpPort: smtpPort,
        displayName: displayName,
      );

      _accounts.add(account);

      if (_selectedAccount == null) {
        _selectedAccount = account;
        await loadFolders();
        if (_folders.isNotEmpty) {
          _selectedFolder = inboxFolder ?? _folders.first;
          await loadEmails();
        }
      }

      if (_connectivity.isOnline.value) {
        await syncAccount(account.id);
      }

      return true;
    } catch (e) {
      debugPrint('Error adding account: $e');
      _error = 'Fehler beim Hinzufügen des Kontos. Bitte versuche es erneut.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeAccount(String accountId) async {
    await _service.removeAccount(accountId);
    _accounts.removeWhere((a) => a.id == accountId);

    if (_selectedAccount?.id == accountId) {
      _selectedAccount = _accounts.firstOrNull;
      _folders = [];
      _emails = [];
      _selectedEmail = null;

      if (_selectedAccount != null) {
        await loadFolders();
        if (_folders.isNotEmpty) {
          _selectedFolder = inboxFolder ?? _folders.first;
          await loadEmails();
        }
      }
    }

    notifyListeners();
  }

  Future<void> syncAccount(String accountId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      await _service.syncAccount(accountId);
      await loadFolders();
      await loadEmails();
    } catch (e) {
      debugPrint('Email sync error: $e');
      _error = 'E-Mail-Sync fehlgeschlagen. Bitte versuche es erneut.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncCurrentAccount() async {
    if (_selectedAccount != null) {
      await syncAccount(_selectedAccount!.id);
    }
  }

  Future<void> markAsRead(String emailId) async {
    await _service.markAsRead(emailId);

    final index = _emails.indexWhere((e) => e.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isRead: true);

      if (_selectedFolder != null) {
        final folderIndex = _folders.indexWhere((f) => f.id == _selectedFolder!.id);
        if (folderIndex != -1) {
          _folders[folderIndex] = _folders[folderIndex].copyWith(
            unreadCount: _folders[folderIndex].unreadCount - 1,
          );
        }
      }

      notifyListeners();
    }
  }

  Future<void> markAsUnread(String emailId) async {
    await _service.markAsUnread(emailId);

    final index = _emails.indexWhere((e) => e.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isRead: false);

      if (_selectedFolder != null) {
        final folderIndex = _folders.indexWhere((f) => f.id == _selectedFolder!.id);
        if (folderIndex != -1) {
          _folders[folderIndex] = _folders[folderIndex].copyWith(
            unreadCount: _folders[folderIndex].unreadCount + 1,
          );
        }
      }

      notifyListeners();
    }
  }

  Future<void> toggleStar(String emailId) async {
    await _service.toggleStar(emailId);

    final index = _emails.indexWhere((e) => e.id == emailId);
    if (index != -1) {
      _emails[index] = _emails[index].copyWith(isStarred: !_emails[index].isStarred);
      notifyListeners();
    }
  }

  Future<void> moveToTrash(String emailId) async {
    await _service.moveToTrash(emailId);
    _emails.removeWhere((e) => e.id == emailId);

    if (_selectedEmail?.id == emailId) {
      _selectedEmail = null;
    }

    notifyListeners();
  }

  Future<void> deleteEmail(String emailId) async {
    await _service.deleteEmail(emailId);
    _emails.removeWhere((e) => e.id == emailId);

    if (_selectedEmail?.id == emailId) {
      _selectedEmail = null;
    }

    notifyListeners();
  }

  Future<bool> sendEmail(EmailDraft draft) async {
    try {
      return await _service.sendEmail(draft);
    } catch (e) {
      debugPrint('Error sending email: $e');
      _error = 'Fehler beim Senden. Bitte versuche es erneut.';
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Email> get filteredEmails {
    if (_searchQuery.isEmpty) return _emails;

    final lowerQuery = _searchQuery.toLowerCase();
    return _emails.where((email) {
      return email.subject.toLowerCase().contains(lowerQuery) ||
             email.from.toLowerCase().contains(lowerQuery) ||
             (email.fromName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
