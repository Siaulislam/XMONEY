/// Local digital wallet provider (destination payout rail).
class WalletProvider {
  const WalletProvider({
    required this.code,
    required this.name,
    required this.description,
    this.logoUrl,
    this.logoAsset,
    this.brandColor = '#1A4B8C',
    this.sortOrder = 0,
  });

  final String code;
  final String name;
  final String description;
  final String? logoUrl;
  final String? logoAsset;
  final String brandColor;
  final int sortOrder;

  String get id => code;

  static WalletProvider? tryParse(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final name = json['name'] as String?;
    if (code == null || name == null) return null;
    return WalletProvider(
      code: code,
      name: name,
      description: json['description'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      logoAsset: json['logo_asset'] as String? ?? json['logoAsset'] as String?,
      brandColor: json['brand_color'] as String? ?? json['brandColor'] as String? ?? '#1A4B8C',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (logoAsset != null) 'logo_asset': logoAsset,
        'brand_color': brandColor,
        'sort_order': sortOrder,
      };
}
