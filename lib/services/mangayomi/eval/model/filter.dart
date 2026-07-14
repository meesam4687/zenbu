class FilterList {
  List<dynamic> filters;
  FilterList(this.filters);
  factory FilterList.fromJson(Map<String, dynamic> json) {
    return FilterList(fromJsonFilterValuesToList(json['filters']));
  }
  Map<String, dynamic> toJson() => {'filters': filterValuesListToJson(filters)};
}

class SelectFilter {
  String? type;
  String name;
  int state;
  List<dynamic> values;
  String? typeName;

  SelectFilter(this.type, this.name, this.state, this.values, this.typeName);
  factory SelectFilter.fromJson(Map<String, dynamic> json) {
    return SelectFilter(
      json['type'],
      json['name'],
      json['state'] ?? 0,
      fromJsonFilterValuesToList(json['values']),
      json['type_name'],
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'state': state,
    'values': filterValuesListToJson(values),
    'type_name': "SelectFilter",
  };
}

class SelectFilterOption {
  String name;
  String value;
  String? typeName;

  SelectFilterOption(this.name, this.value, this.typeName);
  factory SelectFilterOption.fromJson(Map<String, dynamic> json) {
    return SelectFilterOption(json['name'], json['value'], json['type_name']);
  }
  Map<String, dynamic> toJson() => {
    'value': value,
    'name': name,
    'type_name': "SelectOption",
  };
}

class SeparatorFilter {
  String? type;
  String? typeName;
  SeparatorFilter(this.typeName, {this.type = ''});
  factory SeparatorFilter.fromJson(Map<String, dynamic> json) {
    return SeparatorFilter(type: json['type'], json['type_name']);
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'type_name': "SeparatorFilter",
  };
}

class HeaderFilter {
  String? type;
  String name;
  String? typeName;
  HeaderFilter(this.name, this.typeName, {this.type = ''});
  factory HeaderFilter.fromJson(Map<String, dynamic> json) {
    return HeaderFilter(json['name'], json['type_name'], type: json['value']);
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'type_name': "HeaderFilter",
  };
}

class TextFilter {
  String? type;
  String name;
  String state;
  String? typeName;

  TextFilter(this.type, this.name, this.typeName, {this.state = ""});
  factory TextFilter.fromJson(Map<String, dynamic> json) {
    return TextFilter(
      json['type'],
      json['name'],
      json['type_name'],
      state: json['state'] ?? "",
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'state': state,
    'type_name': "TextFilter",
  };
}

class SortFilter {
  String? type;
  String name;
  SortState state;
  List<dynamic> values;
  String? typeName;

  SortFilter(this.type, this.name, this.state, this.values, this.typeName);
  factory SortFilter.fromJson(Map<String, dynamic> json) {
    return SortFilter(
      json['type'],
      json['name'],
      json['state'] == null
          ? SortState(0, false, "")
          : SortState.fromJson(json['state']),
      fromJsonFilterValuesToList(json['values']),
      json['type_name'],
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'state': state.toJson(),
    'values': filterValuesListToJson(values),
    'type_name': "SortFilter",
  };
}

class SortState {
  int index;
  bool ascending;
  String? typeName;

  SortState(this.index, this.ascending, this.typeName);
  factory SortState.fromJson(Map<String, dynamic> json) {
    return SortState(json['index'], json['ascending'], json['type_name']);
  }
  Map<String, dynamic> toJson() => {
    'index': index,
    'ascending': ascending,
    'type_name': "SortState",
  };
}

class TriStateFilter {
  String? type;
  String name;
  String value;
  int state;
  String? typeName;

  factory TriStateFilter.fromJson(Map<String, dynamic> json) {
    return TriStateFilter(
      json['type'],
      json['name'],
      json['value'],
      json['type_name'],
      state: json['state'] ?? 0,
    );
  }
  TriStateFilter(
    this.type,
    this.name,
    this.value,
    this.typeName, {
    this.state = 0,
  });
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'value': value,
    'state': state,
    'type_name': "TriState",
  };
}

class GroupFilter {
  String? type;
  String name;
  List<dynamic> state;
  String? typeName;

  GroupFilter(this.type, this.name, this.state, this.typeName);
  factory GroupFilter.fromJson(Map<String, dynamic> json) {
    return GroupFilter(
      json['type'],
      json['name'],
      fromJsonFilterValuesToList(json['state']),
      json['type_name'],
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'state': filterValuesListToJson(state),
    'type_name': "GroupFilter",
  };
}

class CheckBoxFilter {
  String? type;
  String name;
  String value;
  bool state;
  String? typeName;

  CheckBoxFilter(
    this.type,
    this.name,
    this.value,
    this.typeName, {
    this.state = false,
  });
  factory CheckBoxFilter.fromJson(Map<String, dynamic> json) {
    return CheckBoxFilter(
      json['type'],
      json['name'],
      json['value'],
      json['type_name'],
      state: json['state'] ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'value': value,
    'state': state,
    'type_name': "CheckBox",
  };
}

List<dynamic> fromJsonFilterValuesToList(List list) {
  return list
      .map((e) {
        final map = (e as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );

        return switch (map['type_name']) {
          'TriState' => TriStateFilter.fromJson(map),
          'CheckBox' => CheckBoxFilter.fromJson(map),
          'SelectOption' => SelectFilterOption.fromJson(map),
          'SelectFilter' => SelectFilter.fromJson(map),
          'SeparatorFilter' => SeparatorFilter.fromJson(map),
          'HeaderFilter' => HeaderFilter.fromJson(map),
          'TextFilter' => TextFilter.fromJson(map),
          'SortFilter' => SortFilter.fromJson(map),
          'SortState' => SortState.fromJson(map),
          'GroupFilter' => GroupFilter.fromJson(map),
          _ => null,
        };
      })
      .where((filter) => filter != null)
      .toList();
}

List<Map<String, dynamic>?> filterValuesListToJson(List<dynamic> values) {
  return values.map((e) {
    if (e is SelectFilter) {
      return e.toJson();
    } else if (e is SelectFilterOption) {
      return e.toJson();
    } else if (e is SeparatorFilter) {
      return e.toJson();
    } else if (e is HeaderFilter) {
      return e.toJson();
    } else if (e is TextFilter) {
      return e.toJson();
    } else if (e is SortFilter) {
      return e.toJson();
    } else if (e is SortState) {
      return e.toJson();
    } else if (e is TriStateFilter) {
      return e.toJson();
    } else if (e is GroupFilter) {
      return e.toJson();
    }
    return (e.toJson() as Map<String, dynamic>?);
  }).toList();
}
