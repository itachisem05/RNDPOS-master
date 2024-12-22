import 'package:flutter/material.dart';

class DropdownUtils {
  static Widget buildAutoCompleteDropdown(BuildContext context, List<dynamic> autoCompleteItems, Function(String) onSelect) {
    if (autoCompleteItems.isNotEmpty) {
      if (autoCompleteItems.length > 1) {
        // Show dropdown only if there are more than one item
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF00255D)),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, 4),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
          margin: const EdgeInsets.only(top: 8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: autoCompleteItems.length > 3 ? 200 : (autoCompleteItems.length * 56.0),
            ),
            child: ListView.builder(
              itemCount: autoCompleteItems.length,
              itemBuilder: (context, index) {
                final item = autoCompleteItems[index];
                return ListTile(
                  title: Text('${item['name']}'),
                  onTap: () {
                    onSelect(item['id']);
                  },
                );
              },
            ),
          ),
        );
      } else if (autoCompleteItems.length == 1) {
        // Automatically select the item if there's only one
        final item = autoCompleteItems.first;
        onSelect(item['id']);
      }
    }
    return SizedBox.shrink(); // Return an empty widget if there are no items
  }
}
