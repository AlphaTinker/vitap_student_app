import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:vit_ap_student_app/core/providers/bottom_nav_provider.dart';
import 'package:vit_ap_student_app/core/providers/user_preferences_notifier.dart';
import 'package:vit_ap_student_app/core/utils/show_snackbar.dart';
import 'package:vit_ap_student_app/features/auth/viewmodel/gmail_otp_link_controller.dart';
import 'package:vit_ap_student_app/features/course_page/view/pages/course_page.dart';
import 'package:vit_ap_student_app/features/home/view/pages/faculty_page.dart';

class HomeAppBar extends ConsumerWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPrefs = ref.watch(userPreferencesProvider);
    return SliverAppBar(
      expandedHeight: 100,
      elevation: 0,
      automaticallyImplyLeading: false,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        expandedTitleScale: 1.2,
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Consumer(
              builder: (context, ref, child) {
                return GestureDetector(
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 3;
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(userPrefs.pfpPath),
                  ),
                );
              },
            ),
            Row(
              children: [
                _HomeActionButton(
                  topPadding: 8,
                  tooltip: 'Courses',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (builder) => const CoursePage(),
                      ),
                    );
                  },
                  child: Icon(
                    Iconsax.book_copy,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                _HomeActionButton(
                  topPadding: 4,
                  tooltip: 'Faculties',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (builder) => const FacultiesPage(),
                      ),
                    );
                  },
                  child: Icon(
                    Iconsax.teacher_copy,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Consumer(
                  builder: (context, ref, child) {
                    final gmailState = ref.watch(
                      gmailOtpLinkControllerProvider,
                    );
                    final isBusy = gmailState.isLoading;
                    final linkedEmail = gmailState.asData?.value.email;
                    final isLinked = linkedEmail != null;

                    return _HomeActionButton(
                      topPadding: 8,
                      tooltip: isLinked ? 'Unlink Gmail OTP' : 'Link Gmail OTP',
                      onPressed: isBusy
                          ? null
                          : () async {
                              final controller = ref.read(
                                gmailOtpLinkControllerProvider.notifier,
                              );

                              if (isLinked) {
                                await controller.unlink();
                              } else {
                                await controller.link();
                              }

                              if (!context.mounted) return;

                              final latestState = ref.read(
                                gmailOtpLinkControllerProvider,
                              );
                              latestState.whenOrNull(
                                data: (state) {
                                  showSnackBar(
                                    context,
                                    state.isLinked
                                        ? 'Gmail linked for OTP auto-fill'
                                        : 'Gmail unlinked',
                                    SnackBarType.success,
                                  );
                                },
                                error: (error, _) {
                                  showSnackBar(
                                    context,
                                    error.toString(),
                                    SnackBarType.error,
                                  );
                                },
                              );
                            },
                      child: isBusy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : GmailLinkIcon(isLinked: isLinked),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
    this.topPadding = 0,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String tooltip;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: IconButton(
          tooltip: tooltip,
          splashRadius: 30,
          style: IconButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: onPressed,
          icon: child,
        ),
      ),
    );
  }
}

class GmailLinkIcon extends StatelessWidget {
  const GmailLinkIcon({super.key, required this.isLinked});

  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(24, 18),
          painter: _GmailMarkPainter(
            color: isLinked
                ? Colors.green.shade500
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        Positioned(
          right: -4,
          bottom: -5,
          child: Icon(
            isLinked ? Icons.check_circle : Icons.link,
            size: 12,
            color: isLinked
                ? Colors.green.shade500
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _GmailMarkPainter extends CustomPainter {
  const _GmailMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final envelope = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(3),
    );
    canvas.drawRRect(envelope, borderPaint);

    final flap = Path()
      ..moveTo(1.4, 2)
      ..lineTo(size.width / 2, size.height * 0.62)
      ..lineTo(size.width - 1.4, 2);
    canvas.drawPath(flap, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GmailMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
