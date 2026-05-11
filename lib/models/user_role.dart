enum UserRole {
  parent,
  child,
  independent,
}

extension UserRoleExt on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.child:
        return 'Child';
      case UserRole.independent:
        return 'Adult';
    }
  }

  bool get isParent => this == UserRole.parent;
  bool get isChild => this == UserRole.child;
  bool get isIndependent => this == UserRole.independent;
}
