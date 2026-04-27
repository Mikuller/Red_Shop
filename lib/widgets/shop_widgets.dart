import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/localization/app_language.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/theme/app_theme.dart';

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 210;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 18 : 20,
                backgroundColor: color.withAlpha(40),
                child: Icon(icon, color: color, size: compact ? 18 : 22),
              ),
              SizedBox(height: compact ? 12 : 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 22 : null,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  final Product product;

  const StockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final Color color;
    final String label;

    if (product.stock == 0) {
      color = const Color(0xFFE65D5D);
      label = strings.t('stockOut');
    } else if (product.isLowStock) {
      color = AppTheme.warning;
      label = strings.t('stockLow');
    } else {
      color = AppTheme.success;
      label = strings.t('stockGood');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Text(
        '$label | ${product.stock}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppLanguageProvider>();
    final strings = controller.strings;
    final current = controller.language;
    final shortLabel = current == AppLanguage.english ? 'EN' : 'አማ';

    return PopupMenuButton<AppLanguage>(
      tooltip: strings.t('language'),
      onSelected: context.languageController.setLanguage,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppLanguage.english,
          child: Text(strings.languageLabel(AppLanguage.english)),
        ),
        PopupMenuItem(
          value: AppLanguage.amharic,
          child: Text(strings.languageLabel(AppLanguage.amharic)),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16),
            const SizedBox(width: 6),
            Text(
              shortLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroMetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback? onTap;

  const HeroMetricBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

class ActionShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const ActionShortcutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 200 || constraints.maxWidth < 160;
        return AppPanel(
          onTap: onTap,
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 16 : 20,
                backgroundColor: color.withAlpha(36),
                foregroundColor: color,
                child: Icon(icon, size: compact ? 16 : 22),
              ),
              SizedBox(height: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 16 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 13 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (compact)
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                )
              else
                Text(
                  hint,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: emphasize ? AppTheme.textPrimary : AppTheme.textSecondary,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
