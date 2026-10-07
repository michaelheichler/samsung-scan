# Changelog

This file lists the changes of each version. The release workflow copies the section of a version into its GitHub release.

## [1.1.0] - 2026-10-07

The app now reads your pages on your Mac. Nothing goes to the internet or to a cloud service of Apple.

### Added

1. Searchable PDF. The app reads the text of each page and saves it as an invisible layer. You can search and copy that text in Preview and Spotlight.
2. Document facts. The app shows the type, sender, date, and total of a document, for example "Invoice from Musterfirma GmbH, 14 Mar 2026, €129.90".
3. Suggested file names, such as "2026-03-14 Rechnung Musterfirma.pdf". The word for the type is in the language of the document.
4. Empty pages. The app marks empty pages after a scan and removes them with one click.
5. Straighten, Trim to Content, and Undo Changes in the menu of each page.
6. Document splits. The app suggests where each document of a feeder stack starts. You accept or remove each split, and you save each document as its own PDF.

### Apple Intelligence

1. Type, sender, and the model check of document splits need Apple Intelligence.
2. Every other feature works without it.
3. If you turn on Apple Intelligence later, the app fills in the missing facts.

### Fixed

1. A failed or cancelled export now removes every file it wrote.

## [1.0.0] - 2026-10-06

The first public version.

1. Scan from the glass or from the document feeder.
2. Find network scanners by themselves through Bonjour.
3. Choose a paper size, or drag a frame on a preview.
4. Arrange, delete, and preview pages.
5. Save as PDF, PNG, or JPEG.
6. Install with Homebrew.
