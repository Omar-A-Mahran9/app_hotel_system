import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';

import '../../../../core/widgets/primary_button.dart';
import '../room_list_filter.dart';
import 'sheet_scaffold.dart';

Future<RoomListFilter?> showRoomFilterSheet(
  BuildContext context, {
  required RoomListFilter current,
}) => showModalBottomSheet<RoomListFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (BuildContext context) => _RoomFilterSheet(current: current),
);

class _RoomFilterSheet extends StatefulWidget {
  const _RoomFilterSheet({required this.current});

  final RoomListFilter current;

  @override
  State<_RoomFilterSheet> createState() => _RoomFilterSheetState();
}

class _RoomFilterSheetState extends State<_RoomFilterSheet> {
  late bool _refundable = widget.current.freeCancellationOnly;
  late bool _breakfast = widget.current.breakfastOnly;
  late bool _wifi = widget.current.wifiOnly;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SheetScaffold(
      title: l10n.roomFilterTitle,
      body: <Widget>[
        _FilterOption(
          title: l10n.roomFilterCancellation,
          value: _refundable,
          label: l10n.roomFilterFreeCancellation,
          onChanged: (bool value) => setState(() => _refundable = value),
        ),
        _FilterOption(
          title: l10n.roomFilterMeals,
          value: _breakfast,
          label: l10n.roomFilterBreakfast,
          onChanged: (bool value) => setState(() => _breakfast = value),
        ),
        _FilterOption(
          title: l10n.roomFilterFeatures,
          value: _wifi,
          label: l10n.roomFilterWifi,
          onChanged: (bool value) => setState(() => _wifi = value),
        ),
      ],
      footer: Row(
        children: <Widget>[
          Expanded(
            child: TextButton(
              onPressed: () => setState(() {
                _refundable = false;
                _breakfast = false;
                _wifi = false;
              }),
              child: Text(l10n.roomFilterReset),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: l10n.roomFilterShowResults,
              onPressed: () => Navigator.of(context).pop(
                RoomListFilter(
                  freeCancellationOnly: _refundable,
                  breakfastOnly: _breakfast,
                  wifiOnly: _wifi,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.title,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      CheckboxListTile(
        value: value,
        onChanged: (bool? next) => onChanged(next ?? false),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const Divider(height: 20),
    ],
  );
}
