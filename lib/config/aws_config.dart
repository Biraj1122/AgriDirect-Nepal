class AWSConfig {
  static const String bucketName = 'agridirectproducts';
  static const String region = 'ap-south-1'; // Mumbai

  // Base URL for S3 objects
  static const String s3BaseUrl = 'https://$bucketName.s3.$region.amazonaws.com';

  // If you set up CloudFront later, replace this with your CloudFront domain
  static const String cloudFrontDomain = '';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Handle s3:// protocol URIs
    if (path.startsWith('s3://')) {
      final prefix = 's3://$bucketName/';
      if (path.startsWith(prefix)) {
        final key = path.substring(prefix.length);
        return '$s3BaseUrl/$key';
      }
      // Fallback for other s3:// URIs if they occur
      return path.replaceFirst('s3://', 'https://s3.$region.amazonaws.com/');
    }

    // If it's a relative path, assume it's an S3 key
    if (cloudFrontDomain.isNotEmpty) {
      return 'https://$cloudFrontDomain/$path';
    }
    return '$s3BaseUrl/$path';
  }
}