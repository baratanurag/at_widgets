/// This is a widget to display the initials of an atsign which does not have a profile picture
/// it takes in @param [size] as a double and
/// @param [initials] as String and display those initials in a circular avatar with random colors

import 'package:at_contacts_flutter/utils/colors.dart';
import 'package:at_contacts_flutter/utils/contact_theme.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:at_common_flutter/services/size_config.dart';

// ignore: must_be_immutable
class ContactInitial extends StatelessWidget {
  final double size;
  final String initials;
  int? index;
  final Color? backgroundColor;
  final ContactTheme theme;

  ContactInitial({
    Key? key,
    this.size = 50,
    required this.initials,
    this.index,
    this.backgroundColor,
    this.theme = const DefaultContactTheme(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var encodedInitials = initials.runes;
    if (encodedInitials.length < 3) {
      index = encodedInitials.length;
    } else {
      index = 3;
    }

    return Container(
      height: size.toHeight,
      width: size.toHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? ContactInitialsColors.getColor(initials),
        borderRadius: BorderRadius.circular(size.toWidth),
        border: Border.all(color: theme.avatarBorderColor, width: 2),
      ),
      child: Center(
        child: Text(
          String.fromCharCodes(encodedInitials, (index == 1) ? 0 : 1, index)
              .toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.toFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
