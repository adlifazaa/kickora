/// Store listing for yearly Premium (no purchase tokens).
class PremiumProductOffer {
  const PremiumProductOffer({
    required this.productId,
    required this.priceLabel,
    required this.isAvailable,
  });

  final String productId;
  final String priceLabel;
  final bool isAvailable;
}
