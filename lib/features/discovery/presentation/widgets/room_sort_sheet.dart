import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/room_sort.dart';
import '../discovery_l10n.dart';
import 'sheet_scaffold.dart';

/// `16 · Stay dates & available rooms` — "ترتيب الغرف". Returns the chosen
/// [RoomSort], or `null` if dismissed. Mirrors the hotel sort sheet.
Future<RoomSort?> showRoomSortSheet(
  BuildContext context, {
  required RoomSort current,
}) {
  return showModalBottomSheet<RoomSort>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _RoomSortSheet(current: current),
  );
}

class _RoomSortSheet extends StatefulWidget {
  const _RoomSortSheet({required this.current});

  final RoomSort current;

  @override
  State<_RoomSortSheet> createState() => _RoomSortSheetState();
}

class _RoomSortSheetState extends State<_RoomSortSheet> {
  late RoomSort _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SheetScaffold(
      title: l10n.roomSortTitle,
      body: <Widget>[
        RadioGroup<RoomSort>(
          groupValue: _selected,
          onChanged: (RoomSort? value) =>
              setState(() => _selected = value ?? _selected),
          child: Column(
            children: <Widget>[
              for (final RoomSort sort in RoomSort.values)
                RadioListTile<RoomSort>(
                  value: sort,
                  title: Text(l10n.roomSortLabel(sort)),
                  secondary:
                      _selected == sort ? Text(l10n.roomSortActiveTag) : null,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
      footer: PrimaryButton(
        label: l10n.roomSortApply,
        onPressed: () => Navigator.of(context).pop(_selected),
      ),
    );
  }
}
