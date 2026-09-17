import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Zenbu'**
  String get appTitle;

  /// No description provided for @anime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get anime;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @manga.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get manga;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred application language.'**
  String get appLanguageSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @englishUS.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get englishUS;

  /// No description provided for @englishGB.
  ///
  /// In en, this message translates to:
  /// **'English (UK)'**
  String get englishGB;

  /// No description provided for @loginWith.
  ///
  /// In en, this message translates to:
  /// **'Login with'**
  String get loginWith;

  /// No description provided for @insertSomeLineHere.
  ///
  /// In en, this message translates to:
  /// **'*insert some line here*'**
  String get insertSomeLineHere;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Zenbu looks on your device.'**
  String get themeModeSubtitle;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @personaliseColorScheme.
  ///
  /// In en, this message translates to:
  /// **'Personalize the primary color scheme.'**
  String get personaliseColorScheme;

  /// No description provided for @themeAndColors.
  ///
  /// In en, this message translates to:
  /// **'Theme & Colors'**
  String get themeAndColors;

  /// No description provided for @chooseThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred theme accent color.'**
  String get chooseThemeColor;

  /// No description provided for @homeScreenLayout.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Layout'**
  String get homeScreenLayout;

  /// No description provided for @customTheme.
  ///
  /// In en, this message translates to:
  /// **'Custom Theme'**
  String get customTheme;

  /// No description provided for @customThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a curated handcrafted theme.'**
  String get customThemeSubtitle;

  /// No description provided for @showAnimeList.
  ///
  /// In en, this message translates to:
  /// **'Show Anime List'**
  String get showAnimeList;

  /// No description provided for @showAnimeListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display currently watching anime'**
  String get showAnimeListSubtitle;

  /// No description provided for @showMangaList.
  ///
  /// In en, this message translates to:
  /// **'Show Manga List'**
  String get showMangaList;

  /// No description provided for @showMangaListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display currently reading manga'**
  String get showMangaListSubtitle;

  /// No description provided for @showRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Show Recommendations'**
  String get showRecommendations;

  /// No description provided for @showRecommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display recommendations based on anime list'**
  String get showRecommendationsSubtitle;

  /// No description provided for @aniList.
  ///
  /// In en, this message translates to:
  /// **'AniList'**
  String get aniList;

  /// No description provided for @aniListSettings.
  ///
  /// In en, this message translates to:
  /// **'AniList Settings'**
  String get aniListSettings;

  /// No description provided for @aniListSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure metadata language and content preferences.'**
  String get aniListSettingsSubtitle;

  /// No description provided for @titleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Title Language'**
  String get titleLanguage;

  /// No description provided for @titleLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How titles are shown throughout the app. Synced with your AniList account.'**
  String get titleLanguageSubtitle;

  /// No description provided for @showNsfwContent.
  ///
  /// In en, this message translates to:
  /// **'Show NSFW Content'**
  String get showNsfwContent;

  /// No description provided for @showNsfwContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display adult (18+) anime and manga. Synced with your AniList account.'**
  String get showNsfwContentSubtitle;

  /// No description provided for @romaji.
  ///
  /// In en, this message translates to:
  /// **'Romaji'**
  String get romaji;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @native.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get native;

  /// No description provided for @failedToUpdateTitleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update title language'**
  String get failedToUpdateTitleLanguage;

  /// No description provided for @failedToUpdateNsfwPreference.
  ///
  /// In en, this message translates to:
  /// **'Failed to update NSFW preference'**
  String get failedToUpdateNsfwPreference;

  /// No description provided for @mangayomi.
  ///
  /// In en, this message translates to:
  /// **'Mangayomi'**
  String get mangayomi;

  /// No description provided for @extensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get extensions;

  /// No description provided for @extensionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage sources and repositories for anime & manga.'**
  String get extensionsSubtitle;

  /// No description provided for @extensionsManager.
  ///
  /// In en, this message translates to:
  /// **'Extensions Manager'**
  String get extensionsManager;

  /// No description provided for @searchExtensions.
  ///
  /// In en, this message translates to:
  /// **'Search extensions...'**
  String get searchExtensions;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get installing;

  /// No description provided for @noExtensionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No extensions available.'**
  String get noExtensionsAvailable;

  /// No description provided for @addExtensionRepo.
  ///
  /// In en, this message translates to:
  /// **'Add Extension Repo'**
  String get addExtensionRepo;

  /// No description provided for @addRepository.
  ///
  /// In en, this message translates to:
  /// **'Add Repository'**
  String get addRepository;

  /// No description provided for @removeRepository.
  ///
  /// In en, this message translates to:
  /// **'Remove Repository'**
  String get removeRepository;

  /// No description provided for @repositoryUrl.
  ///
  /// In en, this message translates to:
  /// **'Repository URL'**
  String get repositoryUrl;

  /// No description provided for @urlCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'URL cannot be empty'**
  String get urlCannotBeEmpty;

  /// No description provided for @repositoryAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Repository added successfully!'**
  String get repositoryAddedSuccess;

  /// No description provided for @repositoryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Repository removed'**
  String get repositoryRemoved;

  /// No description provided for @noRepositoriesAdded.
  ///
  /// In en, this message translates to:
  /// **'No repositories added.'**
  String get noRepositoriesAdded;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @repoPromptAdd.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to add a source repo!\nMangayomi extensions / repositories can be used.'**
  String get repoPromptAdd;

  /// No description provided for @repoPromptNextTab.
  ///
  /// In en, this message translates to:
  /// **'Add a repository URL in the next tab first!\nMangayomi extensions / repositories can be used.'**
  String get repoPromptNextTab;

  /// No description provided for @thisExtensionHasNoSettings.
  ///
  /// In en, this message translates to:
  /// **'This extension has no settings.'**
  String get thisExtensionHasNoSettings;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @discord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get discord;

  /// No description provided for @notLinkedTapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Not linked  •  Tap to connect'**
  String get notLinkedTapToConnect;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @unlinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Unlink Account'**
  String get unlinkAccount;

  /// No description provided for @discordAccountUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Discord account unlinked'**
  String get discordAccountUnlinked;

  /// No description provided for @couldNotOpenDiscord.
  ///
  /// In en, this message translates to:
  /// **'Could not open Discord'**
  String get couldNotOpenDiscord;

  /// No description provided for @couldNotOpenGitHub.
  ///
  /// In en, this message translates to:
  /// **'Could not open GitHub'**
  String get couldNotOpenGitHub;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for a newer version of Zenbu'**
  String get checkUpdatesSubtitle;

  /// No description provided for @appIsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date!'**
  String get appIsUpToDate;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @tapToViewAndInstall.
  ///
  /// In en, this message translates to:
  /// **'Tap to view and install'**
  String get tapToViewAndInstall;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @downloadLater.
  ///
  /// In en, this message translates to:
  /// **'Download Later'**
  String get downloadLater;

  /// No description provided for @stopUpdate.
  ///
  /// In en, this message translates to:
  /// **'Stop Update'**
  String get stopUpdate;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available!'**
  String get newVersionAvailable;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @searchList.
  ///
  /// In en, this message translates to:
  /// **'Search list...'**
  String get searchList;

  /// No description provided for @searchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags...'**
  String get searchTags;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search title...'**
  String get searchTitle;

  /// No description provided for @searchAlternativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Alternative Title'**
  String get searchAlternativeTitle;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get typeToSearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResults;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResultsFound;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @genresAndTags.
  ///
  /// In en, this message translates to:
  /// **'Genres and Tags'**
  String get genresAndTags;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @allTags.
  ///
  /// In en, this message translates to:
  /// **'All Tags'**
  String get allTags;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @releaseYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get releaseYear;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @sourceMaterial.
  ///
  /// In en, this message translates to:
  /// **'Source Material'**
  String get sourceMaterial;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @homeScreenIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Home Screen is empty'**
  String get homeScreenIsEmpty;

  /// No description provided for @youPutNothingOnHomescreen.
  ///
  /// In en, this message translates to:
  /// **'You put nothing on the homescreen.'**
  String get youPutNothingOnHomescreen;

  /// No description provided for @openAppearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Appearance Settings'**
  String get openAppearanceSettings;

  /// No description provided for @suchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Such empty'**
  String get suchEmpty;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Empty list'**
  String get emptyList;

  /// No description provided for @simulcasts.
  ///
  /// In en, this message translates to:
  /// **'Simulcasts'**
  String get simulcasts;

  /// No description provided for @errorLoadingSimulcasts.
  ///
  /// In en, this message translates to:
  /// **'Error loading simulcasts'**
  String get errorLoadingSimulcasts;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @relations.
  ///
  /// In en, this message translates to:
  /// **'Relations'**
  String get relations;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @noReviewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reviews available for this media.'**
  String get noReviewsAvailable;

  /// No description provided for @writtenBy.
  ///
  /// In en, this message translates to:
  /// **'Written by'**
  String get writtenBy;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToList;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planning;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @dropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get dropped;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found for this show.'**
  String get noEpisodesFound;

  /// No description provided for @noChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No chapters found for this manga.'**
  String get noChaptersFound;

  /// No description provided for @noAnimeExtensionsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No Extensions Installed'**
  String get noAnimeExtensionsInstalled;

  /// No description provided for @noMangaExtensionsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No Manga Extensions Installed'**
  String get noMangaExtensionsInstalled;

  /// No description provided for @toStartWatchingPrompt.
  ///
  /// In en, this message translates to:
  /// **'To start watching, add repositories and install an anime extension.'**
  String get toStartWatchingPrompt;

  /// No description provided for @toStartReadingPrompt.
  ///
  /// In en, this message translates to:
  /// **'To start reading, add repositories and install a manga extension.'**
  String get toStartReadingPrompt;

  /// No description provided for @manageExtensions.
  ///
  /// In en, this message translates to:
  /// **'Manage Extensions'**
  String get manageExtensions;

  /// No description provided for @mapLocalFolder.
  ///
  /// In en, this message translates to:
  /// **'Map Local Folder'**
  String get mapLocalFolder;

  /// No description provided for @chooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose Directory'**
  String get chooseDirectory;

  /// No description provided for @chooseDownloadQuality.
  ///
  /// In en, this message translates to:
  /// **'Choose Download Quality'**
  String get chooseDownloadQuality;

  /// No description provided for @episodeAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Episode already downloaded.'**
  String get episodeAlreadyDownloaded;

  /// No description provided for @chapterAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Chapter already downloaded.'**
  String get chapterAlreadyDownloaded;

  /// No description provided for @resolvingDownloadLinks.
  ///
  /// In en, this message translates to:
  /// **'Resolving download links...'**
  String get resolvingDownloadLinks;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get deleteDownload;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadOptions.
  ///
  /// In en, this message translates to:
  /// **'Download Options'**
  String get downloadOptions;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @readingMode.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readingMode;

  /// No description provided for @leftToRightSwipe.
  ///
  /// In en, this message translates to:
  /// **'Left to right swipe'**
  String get leftToRightSwipe;

  /// No description provided for @rightToLeftSwipe.
  ///
  /// In en, this message translates to:
  /// **'Right to left swipe'**
  String get rightToLeftSwipe;

  /// No description provided for @verticalScrolling.
  ///
  /// In en, this message translates to:
  /// **'Vertical scrolling'**
  String get verticalScrolling;

  /// No description provided for @webnovel.
  ///
  /// In en, this message translates to:
  /// **'Webnovel'**
  String get webnovel;

  /// No description provided for @pagesLeftToRight.
  ///
  /// In en, this message translates to:
  /// **'Pages go from left to right'**
  String get pagesLeftToRight;

  /// No description provided for @pagesRightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Pages go from right to left'**
  String get pagesRightToLeft;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;

  /// No description provided for @loadingPages.
  ///
  /// In en, this message translates to:
  /// **'Loading pages...'**
  String get loadingPages;

  /// No description provided for @noPagesFound.
  ///
  /// In en, this message translates to:
  /// **'No pages found for this chapter.'**
  String get noPagesFound;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @lineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get lineHeight;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @playbackSettings.
  ///
  /// In en, this message translates to:
  /// **'Playback Settings'**
  String get playbackSettings;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @subtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @customizeSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Customize Subtitles'**
  String get customizeSubtitles;

  /// No description provided for @customizationOptions.
  ///
  /// In en, this message translates to:
  /// **'Customization Options'**
  String get customizationOptions;

  /// No description provided for @presetStyle.
  ///
  /// In en, this message translates to:
  /// **'Preset Style'**
  String get presetStyle;

  /// No description provided for @selectCustomToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select Custom above to edit'**
  String get selectCustomToEdit;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE PREVIEW'**
  String get livePreview;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// No description provided for @fontWeight.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeight;

  /// No description provided for @dropShadow.
  ///
  /// In en, this message translates to:
  /// **'Drop Shadow'**
  String get dropShadow;

  /// No description provided for @dropShadowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds depth and high contrast against bright scenes'**
  String get dropShadowSubtitle;

  /// No description provided for @borderOutline.
  ///
  /// In en, this message translates to:
  /// **'Border Outline'**
  String get borderOutline;

  /// No description provided for @backgroundBox.
  ///
  /// In en, this message translates to:
  /// **'Background Box'**
  String get backgroundBox;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback Failed'**
  String get playbackFailed;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @pictureInPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture in Picture'**
  String get pictureInPicture;

  /// No description provided for @nextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next Episode'**
  String get nextEpisode;

  /// No description provided for @zoomFill.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Fill'**
  String get zoomFill;

  /// No description provided for @zoomFitDefault.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Fit (Default)'**
  String get zoomFitDefault;

  /// No description provided for @zoomStretch.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Stretch'**
  String get zoomStretch;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @doYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get doYouWantToLogout;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender:'**
  String get gender;

  /// No description provided for @voicedBy.
  ///
  /// In en, this message translates to:
  /// **'Voiced By'**
  String get voicedBy;

  /// No description provided for @charactersVoiced.
  ///
  /// In en, this message translates to:
  /// **'Characters Voiced'**
  String get charactersVoiced;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadata;

  /// No description provided for @contentPreferences.
  ///
  /// In en, this message translates to:
  /// **'Content Preferences'**
  String get contentPreferences;

  /// No description provided for @downloadNow.
  ///
  /// In en, this message translates to:
  /// **'Download Now'**
  String get downloadNow;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get failedToLoad;

  /// No description provided for @internetMightNotBeWorking.
  ///
  /// In en, this message translates to:
  /// **'Your Internet might not be working'**
  String get internetMightNotBeWorking;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @currentlyWatching.
  ///
  /// In en, this message translates to:
  /// **'Currently Watching'**
  String get currentlyWatching;

  /// No description provided for @currentlyReading.
  ///
  /// In en, this message translates to:
  /// **'Currently Reading'**
  String get currentlyReading;

  /// No description provided for @animeList.
  ///
  /// In en, this message translates to:
  /// **'Anime List'**
  String get animeList;

  /// No description provided for @mangaList.
  ///
  /// In en, this message translates to:
  /// **'Manga List'**
  String get mangaList;

  /// No description provided for @studios.
  ///
  /// In en, this message translates to:
  /// **'Studios'**
  String get studios;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @searchAnimeFor.
  ///
  /// In en, this message translates to:
  /// **'Search Anime for \"{query}\"'**
  String searchAnimeFor(String query);

  /// No description provided for @searchMangaFor.
  ///
  /// In en, this message translates to:
  /// **'Search Manga for \"{query}\"'**
  String searchMangaFor(String query);

  /// No description provided for @searchCharactersFor.
  ///
  /// In en, this message translates to:
  /// **'Search Characters for \"{query}\"'**
  String searchCharactersFor(String query);

  /// No description provided for @searchStaffFor.
  ///
  /// In en, this message translates to:
  /// **'Search Staff for \"{query}\"'**
  String searchStaffFor(String query);

  /// No description provided for @searchStudiosFor.
  ///
  /// In en, this message translates to:
  /// **'Search Studios for \"{query}\"'**
  String searchStudiosFor(String query);

  /// No description provided for @searchUsersFor.
  ///
  /// In en, this message translates to:
  /// **'Search Users for \"{query}\"'**
  String searchUsersFor(String query);

  /// No description provided for @unknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown Name'**
  String get unknownName;

  /// No description provided for @unknownStudio.
  ///
  /// In en, this message translates to:
  /// **'Unknown Studio'**
  String get unknownStudio;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYear;

  /// No description provided for @totalRewatches.
  ///
  /// In en, this message translates to:
  /// **'Total Rewatches'**
  String get totalRewatches;

  /// No description provided for @totalRereads.
  ///
  /// In en, this message translates to:
  /// **'Total Rereads'**
  String get totalRereads;

  /// No description provided for @watching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watching;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @rewatching.
  ///
  /// In en, this message translates to:
  /// **'Rewatching'**
  String get rewatching;

  /// No description provided for @rereading.
  ///
  /// In en, this message translates to:
  /// **'Rereading'**
  String get rereading;

  /// No description provided for @meanScore.
  ///
  /// In en, this message translates to:
  /// **'Mean Score'**
  String get meanScore;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @episodeDuration.
  ///
  /// In en, this message translates to:
  /// **'Episode Duration'**
  String get episodeDuration;

  /// No description provided for @alternativeTitles.
  ///
  /// In en, this message translates to:
  /// **'Alternative Titles'**
  String get alternativeTitles;

  /// No description provided for @episodeIn.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode} in'**
  String episodeIn(Object episode);

  /// No description provided for @episodeWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode: {number}'**
  String episodeWithNumber(Object number);

  /// No description provided for @downloadWithEpisode.
  ///
  /// In en, this message translates to:
  /// **'Download {episode}'**
  String downloadWithEpisode(String episode);

  /// No description provided for @episodesCount.
  ///
  /// In en, this message translates to:
  /// **'Episodes: {aired}/{total}'**
  String episodesCount(Object aired, Object total);

  /// No description provided for @eps.
  ///
  /// In en, this message translates to:
  /// **'eps'**
  String get eps;

  /// No description provided for @ch.
  ///
  /// In en, this message translates to:
  /// **'ch'**
  String get ch;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get mins;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @spring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get spring;

  /// No description provided for @summer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer;

  /// No description provided for @fall.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get fall;

  /// No description provided for @winter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get winter;

  /// No description provided for @china.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get china;

  /// No description provided for @japan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get japan;

  /// No description provided for @korea.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get korea;

  /// No description provided for @tv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get tv;

  /// No description provided for @tvShort.
  ///
  /// In en, this message translates to:
  /// **'TV Short'**
  String get tvShort;

  /// No description provided for @movie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get movie;

  /// No description provided for @special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get special;

  /// No description provided for @ova.
  ///
  /// In en, this message translates to:
  /// **'OVA'**
  String get ova;

  /// No description provided for @ona.
  ///
  /// In en, this message translates to:
  /// **'ONA'**
  String get ona;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @mangaFormat.
  ///
  /// In en, this message translates to:
  /// **'Manga'**
  String get mangaFormat;

  /// No description provided for @novel.
  ///
  /// In en, this message translates to:
  /// **'Novel'**
  String get novel;

  /// No description provided for @oneShot.
  ///
  /// In en, this message translates to:
  /// **'One Shot'**
  String get oneShot;

  /// No description provided for @releasing.
  ///
  /// In en, this message translates to:
  /// **'Releasing'**
  String get releasing;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @notReleasedYet.
  ///
  /// In en, this message translates to:
  /// **'Not released yet'**
  String get notReleasedYet;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @hiatus.
  ///
  /// In en, this message translates to:
  /// **'Hiatus'**
  String get hiatus;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @lightNovel.
  ///
  /// In en, this message translates to:
  /// **'Light Novel'**
  String get lightNovel;

  /// No description provided for @visualNovel.
  ///
  /// In en, this message translates to:
  /// **'Visual Novel'**
  String get visualNovel;

  /// No description provided for @videoGame.
  ///
  /// In en, this message translates to:
  /// **'Video Game'**
  String get videoGame;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @doujinshi.
  ///
  /// In en, this message translates to:
  /// **'Doujinshi'**
  String get doujinshi;

  /// No description provided for @webNovel.
  ///
  /// In en, this message translates to:
  /// **'Web Novel'**
  String get webNovel;

  /// No description provided for @liveAction.
  ///
  /// In en, this message translates to:
  /// **'Live Action'**
  String get liveAction;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @comic.
  ///
  /// In en, this message translates to:
  /// **'Comic'**
  String get comic;

  /// No description provided for @multimediaProject.
  ///
  /// In en, this message translates to:
  /// **'Multimedia Project'**
  String get multimediaProject;

  /// No description provided for @pictureBook.
  ///
  /// In en, this message translates to:
  /// **'Picture Book'**
  String get pictureBook;

  /// No description provided for @titleAZ.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get titleAZ;

  /// No description provided for @popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// No description provided for @scoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreDesc;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @dateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @airingStatus.
  ///
  /// In en, this message translates to:
  /// **'Airing Status'**
  String get airingStatus;

  /// No description provided for @lessThanAnHour.
  ///
  /// In en, this message translates to:
  /// **'Less than an hour'**
  String get lessThanAnHour;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String areYouSureDelete(String name);

  /// No description provided for @readingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reading settings...'**
  String get readingSettings;

  /// No description provided for @progressWithValues.
  ///
  /// In en, this message translates to:
  /// **'Progress: {progress}/{total}'**
  String progressWithValues(Object progress, Object total);

  /// No description provided for @scoreWithMax.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / 100'**
  String scoreWithMax(Object score);

  /// No description provided for @failedToToggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle favorite: {error}'**
  String failedToToggleFavorite(String error);

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(num count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(num count);

  /// No description provided for @failedToLoadVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video clip'**
  String get failedToLoadVideoClip;

  /// No description provided for @resolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving...'**
  String get resolving;

  /// No description provided for @downloadedChaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 downloaded chapter} other{{count} downloaded chapters}}'**
  String downloadedChaptersCount(num count);

  /// No description provided for @downloadedEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 downloaded episode} other{{count} downloaded episodes}}'**
  String downloadedEpisodesCount(num count);

  /// No description provided for @noDownloadedMediaFound.
  ///
  /// In en, this message translates to:
  /// **'No downloaded {type} found.'**
  String noDownloadedMediaFound(String type);

  /// No description provided for @downloadingWithCount.
  ///
  /// In en, this message translates to:
  /// **'Downloading ({count})'**
  String downloadingWithCount(int count);

  /// No description provided for @failedToLoadLocalImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load local image'**
  String get failedToLoadLocalImage;

  /// No description provided for @failedToLoadChapter.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapter'**
  String get failedToLoadChapter;

  /// No description provided for @chapterIndex.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterIndex(Object number);

  /// No description provided for @selectQuality.
  ///
  /// In en, this message translates to:
  /// **'Select Quality'**
  String get selectQuality;

  /// No description provided for @selectSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Select Subtitles'**
  String get selectSubtitles;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pageOutOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / {total}'**
  String pageOutOfTotal(int page, int total);

  /// No description provided for @chapterOutOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Chapter {chapter} of {total}'**
  String chapterOutOfTotal(int chapter, int total);

  /// No description provided for @chapterProgress.
  ///
  /// In en, this message translates to:
  /// **'Ch. {chapter} / {total} • {progress}%'**
  String chapterProgress(int chapter, int total, int progress);

  /// No description provided for @fontSizePt.
  ///
  /// In en, this message translates to:
  /// **'Font Size: {size}pt'**
  String fontSizePt(int size);

  /// No description provided for @lineHeightValue.
  ///
  /// In en, this message translates to:
  /// **'Line Height: {height}'**
  String lineHeightValue(String height);

  /// No description provided for @subtitlePreviewText.
  ///
  /// In en, this message translates to:
  /// **'Subtitles will look like this\nAnime subtitle preview'**
  String get subtitlePreviewText;

  /// No description provided for @defaultOption.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultOption;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @semiBold.
  ///
  /// In en, this message translates to:
  /// **'Semi-Bold'**
  String get semiBold;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get colorCoral;

  /// No description provided for @borderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get borderNone;

  /// No description provided for @borderThin.
  ///
  /// In en, this message translates to:
  /// **'Thin (1.5px)'**
  String get borderThin;

  /// No description provided for @borderMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (2.8px)'**
  String get borderMedium;

  /// No description provided for @borderThick.
  ///
  /// In en, this message translates to:
  /// **'Thick (4.0px)'**
  String get borderThick;

  /// No description provided for @bgNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get bgNone;

  /// No description provided for @bgSubtle.
  ///
  /// In en, this message translates to:
  /// **'Subtle (30%)'**
  String get bgSubtle;

  /// No description provided for @bgMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (60%)'**
  String get bgMedium;

  /// No description provided for @bgSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid (100%)'**
  String get bgSolid;

  /// No description provided for @resolvingStreamLinks.
  ///
  /// In en, this message translates to:
  /// **'Resolving stream links...'**
  String get resolvingStreamLinks;

  /// No description provided for @initializingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Initializing player...'**
  String get initializingPlayer;

  /// No description provided for @skipOpening.
  ///
  /// In en, this message translates to:
  /// **'Skip Opening'**
  String get skipOpening;

  /// No description provided for @skipEnding.
  ///
  /// In en, this message translates to:
  /// **'Skip Ending'**
  String get skipEnding;

  /// No description provided for @skipRecap.
  ///
  /// In en, this message translates to:
  /// **'Skip Recap'**
  String get skipRecap;

  /// No description provided for @addExtensionRepoDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the JSON URL of the repository (e.g. Mangayomi compatible repositories)'**
  String get addExtensionRepoDescription;

  /// No description provided for @noTypeExtensionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No {type} extensions available.'**
  String noTypeExtensionsAvailable(String type);

  /// No description provided for @noExtensionsFound.
  ///
  /// In en, this message translates to:
  /// **'No extensions found.'**
  String get noExtensionsFound;

  /// No description provided for @removeRepoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the repository \"{name}\"? This will hide its extensions from the list.'**
  String removeRepoConfirm(String name);

  /// No description provided for @failedToLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings:\n{error}'**
  String failedToLoadSettings(String error);

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @chooseSetting.
  ///
  /// In en, this message translates to:
  /// **'Choose setting'**
  String get chooseSetting;

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// No description provided for @editSetting.
  ///
  /// In en, this message translates to:
  /// **'Edit Setting'**
  String get editSetting;

  /// No description provided for @repositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get repositories;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @repeating.
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get repeating;

  /// No description provided for @studioDetails.
  ///
  /// In en, this message translates to:
  /// **'Studio Details'**
  String get studioDetails;

  /// No description provided for @studioDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Studio details not found.'**
  String get studioDetailsNotFound;

  /// No description provided for @userNotFoundOnAniList.
  ///
  /// In en, this message translates to:
  /// **'User not found on AniList'**
  String get userNotFoundOnAniList;

  /// No description provided for @totalAnime.
  ///
  /// In en, this message translates to:
  /// **'Total Anime'**
  String get totalAnime;

  /// No description provided for @daysWatched.
  ///
  /// In en, this message translates to:
  /// **'Days Watched'**
  String get daysWatched;

  /// No description provided for @daysPlanned.
  ///
  /// In en, this message translates to:
  /// **'Days Planned'**
  String get daysPlanned;

  /// No description provided for @stdDeviation.
  ///
  /// In en, this message translates to:
  /// **'Std Deviation'**
  String get stdDeviation;

  /// No description provided for @totalManga.
  ///
  /// In en, this message translates to:
  /// **'Total Manga'**
  String get totalManga;

  /// No description provided for @chaptersRead.
  ///
  /// In en, this message translates to:
  /// **'Chapters Read'**
  String get chaptersRead;

  /// No description provided for @volumesRead.
  ///
  /// In en, this message translates to:
  /// **'Volumes Read'**
  String get volumesRead;

  /// No description provided for @plannedManga.
  ///
  /// In en, this message translates to:
  /// **'Planned Manga'**
  String get plannedManga;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entries;

  /// No description provided for @animeStatistics.
  ///
  /// In en, this message translates to:
  /// **'Anime Statistics'**
  String get animeStatistics;

  /// No description provided for @mangaStatistics.
  ///
  /// In en, this message translates to:
  /// **'Manga Statistics'**
  String get mangaStatistics;

  /// No description provided for @genreOverview.
  ///
  /// In en, this message translates to:
  /// **'Genre Overview'**
  String get genreOverview;

  /// No description provided for @scoreDistribution.
  ///
  /// In en, this message translates to:
  /// **'Score Distribution'**
  String get scoreDistribution;

  /// No description provided for @episodeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Episode Distribution'**
  String get episodeDistribution;

  /// No description provided for @chapterDistribution.
  ///
  /// In en, this message translates to:
  /// **'Chapter Distribution'**
  String get chapterDistribution;

  /// No description provided for @formatDistribution.
  ///
  /// In en, this message translates to:
  /// **'Format Distribution'**
  String get formatDistribution;

  /// No description provided for @statusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Status Distribution'**
  String get statusDistribution;

  /// No description provided for @countryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Country Distribution'**
  String get countryDistribution;

  /// No description provided for @releaseYearDistribution.
  ///
  /// In en, this message translates to:
  /// **'Release Year Distribution'**
  String get releaseYearDistribution;

  /// No description provided for @watchYearDistribution.
  ///
  /// In en, this message translates to:
  /// **'Watch Year Distribution'**
  String get watchYearDistribution;

  /// No description provided for @readYearDistribution.
  ///
  /// In en, this message translates to:
  /// **'Read Year Distribution'**
  String get readYearDistribution;

  /// No description provided for @mostWatchedVoiceActors.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Voice Actors'**
  String get mostWatchedVoiceActors;

  /// No description provided for @mostWatchedStudios.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Studios'**
  String get mostWatchedStudios;

  /// No description provided for @mostWatchedStaff.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Staff'**
  String get mostWatchedStaff;

  /// No description provided for @mostReadStaff.
  ///
  /// In en, this message translates to:
  /// **'Most Read Staff'**
  String get mostReadStaff;

  /// No description provided for @userMediaListTitle.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s {mediaType} List'**
  String userMediaListTitle(String username, String mediaType);

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Entries'**
  String entriesCount(int count);

  /// No description provided for @barChartTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count} entries ({percentage}%)'**
  String barChartTooltip(String label, int count, String percentage);

  /// No description provided for @entriesInYear.
  ///
  /// In en, this message translates to:
  /// **'{count} entries in {year}'**
  String entriesInYear(int count, int year);

  /// No description provided for @minusSeconds.
  ///
  /// In en, this message translates to:
  /// **'- {seconds} seconds'**
  String minusSeconds(int seconds);

  /// No description provided for @plusSeconds.
  ///
  /// In en, this message translates to:
  /// **'+ {seconds} seconds'**
  String plusSeconds(int seconds);

  /// No description provided for @failedToInstallUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update: {error}'**
  String failedToInstallUpdate(String error);

  /// No description provided for @failedToDownloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update: {error}'**
  String failedToDownloadUpdate(String error);

  /// No description provided for @searchEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchEllipsis;

  /// No description provided for @pip.
  ///
  /// In en, this message translates to:
  /// **'Picture in Picture'**
  String get pip;

  /// No description provided for @zoomMode.
  ///
  /// In en, this message translates to:
  /// **'Zoom Mode'**
  String get zoomMode;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @linkedPresenceActive.
  ///
  /// In en, this message translates to:
  /// **'Linked • Presence active'**
  String get linkedPresenceActive;

  /// No description provided for @linkedPresencePaused.
  ///
  /// In en, this message translates to:
  /// **'Linked • Presence paused'**
  String get linkedPresencePaused;

  /// No description provided for @checkForNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'Check for a newer version of Zenbu'**
  String get checkForNewerVersion;

  /// No description provided for @updateAvailableWithVersion.
  ///
  /// In en, this message translates to:
  /// **'Update Available • {version}'**
  String updateAvailableWithVersion(String version);

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @popularThisSeason.
  ///
  /// In en, this message translates to:
  /// **'Popular this season'**
  String get popularThisSeason;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @allTimePopular.
  ///
  /// In en, this message translates to:
  /// **'All Time Popular'**
  String get allTimePopular;

  /// No description provided for @highestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get highestRated;

  /// No description provided for @displayCurrentlyWatchingAnime.
  ///
  /// In en, this message translates to:
  /// **'Display currently watching anime'**
  String get displayCurrentlyWatchingAnime;

  /// No description provided for @displayCurrentlyReadingManga.
  ///
  /// In en, this message translates to:
  /// **'Display currently reading manga'**
  String get displayCurrentlyReadingManga;

  /// No description provided for @displayRecommendationsBasedOnAnime.
  ///
  /// In en, this message translates to:
  /// **'Display recommendations based on anime list'**
  String get displayRecommendationsBasedOnAnime;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fill;

  /// No description provided for @stretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get stretch;

  /// No description provided for @fit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fit;

  /// No description provided for @unableToLoadVideoStream.
  ///
  /// In en, this message translates to:
  /// **'Unable to load video stream. Please check your internet connection and try again.'**
  String get unableToLoadVideoStream;

  /// No description provided for @noVideoStreamsFound.
  ///
  /// In en, this message translates to:
  /// **'No video streams found. Please check your internet connection and try again.'**
  String get noVideoStreamsFound;

  /// No description provided for @downloadedVideoCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The downloaded video file is corrupt or invalid.\n(An HTML error page or incomplete stream was saved instead of video data).\n\nPlease delete this download and try again.'**
  String get downloadedVideoCorrupt;

  /// No description provided for @errorLoadingRepos.
  ///
  /// In en, this message translates to:
  /// **'Error loading repos: {error}'**
  String errorLoadingRepos(String error);

  /// No description provided for @errorLoadingExtensions.
  ///
  /// In en, this message translates to:
  /// **'Error loading extensions: {error}'**
  String errorLoadingExtensions(String error);

  /// No description provided for @repositoryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Repository added successfully!'**
  String get repositoryAddedSuccessfully;

  /// No description provided for @failedToAddRepository.
  ///
  /// In en, this message translates to:
  /// **'Failed to add repository: {error}'**
  String failedToAddRepository(String error);

  /// No description provided for @errorRemovingRepository.
  ///
  /// In en, this message translates to:
  /// **'Error removing repository: {error}'**
  String errorRemovingRepository(String error);

  /// No description provided for @installingExtension.
  ///
  /// In en, this message translates to:
  /// **'Installing {name}...'**
  String installingExtension(String name);

  /// No description provided for @extensionInstalledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{name} installed successfully!'**
  String extensionInstalledSuccessfully(String name);

  /// No description provided for @failedToInstallExtension.
  ///
  /// In en, this message translates to:
  /// **'Failed to install {name}: {error}'**
  String failedToInstallExtension(String name, String error);

  /// No description provided for @extensionUninstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} uninstalled'**
  String extensionUninstalled(String name);

  /// No description provided for @failedToUninstallExtension.
  ///
  /// In en, this message translates to:
  /// **'Failed to uninstall {name}: {error}'**
  String failedToUninstallExtension(String name, String error);

  /// No description provided for @versionWithLang.
  ///
  /// In en, this message translates to:
  /// **'Version {version} • {lang}'**
  String versionWithLang(String version, String lang);

  /// No description provided for @langMulti.
  ///
  /// In en, this message translates to:
  /// **'Multi-language'**
  String get langMulti;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJapanese;

  /// No description provided for @langChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get langChinese;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKorean;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @langPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get langPortuguese;

  /// No description provided for @langPortugueseBrazil.
  ///
  /// In en, this message translates to:
  /// **'Portuguese (Brazil)'**
  String get langPortugueseBrazil;

  /// No description provided for @langItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get langItalian;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @langTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get langTurkish;

  /// No description provided for @langPolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get langPolish;

  /// No description provided for @langUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get langUkrainian;

  /// No description provided for @langIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get langIndonesian;

  /// No description provided for @langThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get langThai;

  /// No description provided for @langVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get langVietnamese;

  /// No description provided for @failedToUpdateTitleLanguageWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update title language: {error}'**
  String failedToUpdateTitleLanguageWithError(String error);

  /// No description provided for @failedToUpdateNsfwPreferenceWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update NSFW preference: {error}'**
  String failedToUpdateNsfwPreferenceWithError(String error);

  /// No description provided for @failedToLoadChapterContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chapter content: {error}'**
  String failedToLoadChapterContent(String error);

  /// No description provided for @fontFamilySerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get fontFamilySerif;

  /// No description provided for @fontFamilySansSerif.
  ///
  /// In en, this message translates to:
  /// **'Sans-Serif'**
  String get fontFamilySansSerif;

  /// No description provided for @fontFamilyMonospace.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get fontFamilyMonospace;

  /// No description provided for @failedToLoadPages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pages: {error}'**
  String failedToLoadPages(String error);

  /// No description provided for @localSource.
  ///
  /// In en, this message translates to:
  /// **'Local Source'**
  String get localSource;

  /// No description provided for @failedToLoadExtensions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load extensions: {error}'**
  String failedToLoadExtensions(String error);

  /// No description provided for @cloudflareChallengeDetected.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare challenge detected.'**
  String get cloudflareChallengeDetected;

  /// No description provided for @errorLoadingChapters.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading chapters: {error}'**
  String errorLoadingChapters(String error);

  /// No description provided for @errorLoadingEpisodes.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading episodes: {error}'**
  String errorLoadingEpisodes(String error);

  /// No description provided for @customLinkActive.
  ///
  /// In en, this message translates to:
  /// **'Custom Link Active (Tap to edit/reset)'**
  String get customLinkActive;

  /// No description provided for @mapCustomLinkWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Map Custom Link / Wrong Title'**
  String get mapCustomLinkWrongTitle;

  /// No description provided for @wrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong Title'**
  String get wrongTitle;

  /// No description provided for @localDirectoryNotConfiguredOrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Local directory is not configured or does not exist.'**
  String get localDirectoryNotConfiguredOrNotFound;

  /// No description provided for @noMatchingMangaFolderFound.
  ///
  /// In en, this message translates to:
  /// **'No matching manga folder found.'**
  String get noMatchingMangaFolderFound;

  /// No description provided for @noMatchingAnimeFolderFound.
  ///
  /// In en, this message translates to:
  /// **'No matching anime folder found.'**
  String get noMatchingAnimeFolderFound;

  /// No description provided for @noFolderMatchingFound.
  ///
  /// In en, this message translates to:
  /// **'No folder matching \"{title}\" found in local directory.'**
  String noFolderMatchingFound(String title);

  /// No description provided for @cloudflareCaptchaPrompt.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare might be preventing fetching. Try opening in browser and completing the captcha.'**
  String get cloudflareCaptchaPrompt;

  /// No description provided for @errorLoadingChaptersShort.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading chapters.'**
  String get errorLoadingChaptersShort;

  /// No description provided for @errorLoadingEpisodesShort.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading episodes.'**
  String get errorLoadingEpisodesShort;

  /// No description provided for @noChaptersFoundForManga.
  ///
  /// In en, this message translates to:
  /// **'No chapters found for this manga.'**
  String get noChaptersFoundForManga;

  /// No description provided for @noEpisodesFoundForShow.
  ///
  /// In en, this message translates to:
  /// **'No episodes found for this show.'**
  String get noEpisodesFoundForShow;

  /// No description provided for @failedToLoadExtensionEngine.
  ///
  /// In en, this message translates to:
  /// **'Failed to load extension engine: {error}'**
  String failedToLoadExtensionEngine(String error);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @searchTitleEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Search title...'**
  String get searchTitleEllipsis;

  /// No description provided for @noStreamLinksFound.
  ///
  /// In en, this message translates to:
  /// **'No stream links found.'**
  String get noStreamLinksFound;

  /// No description provided for @unknownQuality.
  ///
  /// In en, this message translates to:
  /// **'Unknown Quality'**
  String get unknownQuality;

  /// No description provided for @unknownGraphQLError.
  ///
  /// In en, this message translates to:
  /// **'Unknown GraphQL error'**
  String get unknownGraphQLError;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @notificationEpisodeAired.
  ///
  /// In en, this message translates to:
  /// **'Episode {episode} of {title} aired'**
  String notificationEpisodeAired(String episode, String title);

  /// No description provided for @notificationMediaAdded.
  ///
  /// In en, this message translates to:
  /// **'{title} was recently added to the site.'**
  String notificationMediaAdded(String title);

  /// No description provided for @notificationMediaDataChanged.
  ///
  /// In en, this message translates to:
  /// **'{title} received site data changes'**
  String notificationMediaDataChanged(String title);

  /// No description provided for @notificationMediaMerged.
  ///
  /// In en, this message translates to:
  /// **'{deletedTitle} was merged with {title}'**
  String notificationMediaMerged(String deletedTitle, String title);

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @noValidExtensionUrlFound.
  ///
  /// In en, this message translates to:
  /// **'No valid extension URL found in link.'**
  String get noValidExtensionUrlFound;

  /// No description provided for @communityRepo.
  ///
  /// In en, this message translates to:
  /// **'Community Repo'**
  String get communityRepo;

  /// No description provided for @addedRepository.
  ///
  /// In en, this message translates to:
  /// **'Added repository: {name}'**
  String addedRepository(String name);

  /// No description provided for @loginToViewAndInstallExtensions.
  ///
  /// In en, this message translates to:
  /// **'Log in to view and install extensions!'**
  String get loginToViewAndInstallExtensions;

  /// No description provided for @allFilesAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'All Files Access Required'**
  String get allFilesAccessRequired;

  /// No description provided for @allFilesAccessPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To play local videos and read local manga chapters/archives from external directories on Android 11+, Zenbu requires \"All Files Access\" permission.'**
  String get allFilesAccessPermissionDescription;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @failedToPickDirectory.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick directory: {error}'**
  String failedToPickDirectory(String error);

  /// No description provided for @openingDiscordForAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Opening Discord for Authorization...'**
  String get openingDiscordForAuthorization;

  /// No description provided for @couldNotOpenAuthorizationBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open authorization browser.'**
  String get couldNotOpenAuthorizationBrowser;

  /// No description provided for @errorOpeningAuthorizationPage.
  ///
  /// In en, this message translates to:
  /// **'Error opening authorization page: {error}'**
  String errorOpeningAuthorizationPage(String error);

  /// No description provided for @connectingToDiscord.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Discord...'**
  String get connectingToDiscord;

  /// No description provided for @oauth2CodeVerifierMissing.
  ///
  /// In en, this message translates to:
  /// **'OAuth2 code verifier missing.'**
  String get oauth2CodeVerifierMissing;

  /// No description provided for @failedToLinkDiscordAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to link Discord account.'**
  String get failedToLinkDiscordAccount;

  /// No description provided for @discordRichPresenceActive.
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence Active!'**
  String get discordRichPresenceActive;

  /// No description provided for @failedToStartDiscordPresenceConnection.
  ///
  /// In en, this message translates to:
  /// **'Failed to start Discord presence connection.'**
  String get failedToStartDiscordPresenceConnection;

  /// No description provided for @errorConnectingToDiscord.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to Discord.'**
  String get errorConnectingToDiscord;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
