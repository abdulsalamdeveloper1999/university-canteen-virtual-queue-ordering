import 'dart:developer';
import 'dart:typed_data';
import 'package:cloudinary/cloudinary.dart';

class CloudinaryService {
  final Cloudinary cloudinary = Cloudinary.signedConfig(
    apiKey: "547413896474848",
    apiSecret: "_2u7kTvbnTTxOixZ0C_S4BN0SAs",
    cloudName: "dpqpnvn8u",
  );

  Future<String?> uploadImage({
    required Uint8List fileBytes,
  }) async {
    try {
      final CloudinaryResponse response = await cloudinary.upload(
        fileBytes: fileBytes,
        resourceType: CloudinaryResourceType.image,
        folder: 'canteen_app',
        progressCallback: (count, total) {
          log('Uploading image: $count/$total');
        },
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        log("Upload failed: ${response.error?.toString()}");
        return null;
      }
    } catch (e) {
      log("Error uploading image to Cloudinary: $e");
      return null;
    }
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final publicId = pathSegments[pathSegments.length - 1].split('.').first;

      final response = await cloudinary.destroy(
        'canteen_app/$publicId',
        resourceType: CloudinaryResourceType.image,
      );

      return response.isSuccessful;
    } catch (e) {
      log("Error deleting image from Cloudinary: $e");
      return false;
    }
  }
}
