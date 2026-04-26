enum CatalogItemStatus {
  active,
  inactive,
  deleted;

  static CatalogItemStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return CatalogItemStatus.active;
      case 'inactive':
        return CatalogItemStatus.inactive;
      case 'deleted':
        return CatalogItemStatus.deleted;
      default:
        return CatalogItemStatus.inactive;
    }
  }

  String get displayName {
    switch (this) {
      case CatalogItemStatus.active:
        return 'Active';
      case CatalogItemStatus.inactive:
        return 'Inactive';
      case CatalogItemStatus.deleted:
        return 'Deleted';
    }
  }
}
