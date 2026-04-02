import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'common_widgets.dart';

class DeliveryFailureResult {
  final String reason;
  final String? notes;

  const DeliveryFailureResult({required this.reason, this.notes});
}

Future<DeliveryFailureResult?> showDeliveryFailureSheet(
  BuildContext context, {
  required List<String> reasons,
}) {
  final notesController = TextEditingController();
  String? selectedReason;

  return showModalBottomSheet<DeliveryFailureResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutralMid,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Text(
                'Báo cáo giao hàng thất bại',
                style: AppTypography.header2.copyWith(
                  fontSize: 20,
                  color: AppColors.neutralDark,
                ),
              ),
              const SizedBox(height: 12),

              // Error icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report,
                  size: 32,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lý do',
                  style: AppTypography.header3.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                key: ValueKey(selectedReason),
                initialValue: selectedReason,
                items: reasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedReason = value),
                decoration: InputDecoration(
                  hintText: 'Chọn lý do',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.neutralLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.neutralLight),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Warning note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  border: Border.all(
                    color: AppColors.primaryGradientStart.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.header3.copyWith(
                      color: const Color(0xFF884A00),
                      fontSize: 14,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Lưu ý: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'Vui lòng chọn đúng lý do để hệ thống xử lý nhanh hơn.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Cancel — outline button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: AppColors.neutralLight),
                        foregroundColor: AppColors.neutralDark,
                      ),
                      child: Text(
                        'Hủy',
                        style: AppTypography.subHeader.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm — gradient when active, grey when disabled
                  Expanded(
                    child: AppGradientButton(
                      onPressed: selectedReason == null
                          ? null
                          : () => Navigator.pop(
                                context,
                                DeliveryFailureResult(
                                  reason: selectedReason!,
                                  notes: notesController.text.trim().isEmpty
                                      ? null
                                      : notesController.text.trim(),
                                ),
                              ),
                      borderRadius: 16,
                      child: Text(
                        'Xác nhận',
                        style: AppTypography.subHeader.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
