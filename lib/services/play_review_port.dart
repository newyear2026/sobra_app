import 'package:in_app_review/in_app_review.dart';

import 'app_review_service.dart';
import 'play_listing.dart';

/// Play's in-app review sheet, and the listing for the row that must open
/// something every time.
///
/// The row does not go through `InAppReview.openStoreListing`: it would work,
/// but [openPlayListing] already knows how to fall back to the web page on a
/// phone without the Play app, and the update prompt relies on it too.
final class PlayReviewPort implements AppReviewPort {
  const PlayReviewPort();

  @override
  Future<void> requestReview() async {
    final review = InAppReview.instance;
    // False on any build Play did not install and on a phone without Play
    // services — the same cases the update check shrugs off.
    if (!await review.isAvailable()) return;
    await review.requestReview();
  }

  @override
  Future<bool> openStore() => openPlayListing();
}
