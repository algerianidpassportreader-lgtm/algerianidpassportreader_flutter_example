import 'package:flutter/services.dart';
import 'dart:io';
import 'package:aaaa_project/constants.dart';

class AlgerianIdSdk {
  static const MethodChannel _channel = MethodChannel('algerian_id_sdk');

  // NFC event callbacks
  static Function()? onNFCSessionStart;
  static Function()? onNFCSessionFinish;
  static Function(Map<dynamic, dynamic>)? onPassportDataRead;
  static Function(String)? onNFCError;
  static Function(String)? onAccessDenied;
  static Function(String)? onBACDenied;
  static Function(String)? onPACEError;
  static Function(String)? onCardError;

  // Store token internally
  static bool _isInitialized = false;

  // NEW initialize - requires token
  static Future<bool> initializeWithToken() async {
    try {
      // to listen to android update
      _setupMethodHandler();
      final result = await _channel.invokeMethod('initializeWithToken', {
        'userToken': Constants.userToken,
      });
      _isInitialized = result == true;
      return _isInitialized;
    } on PlatformException catch (e) {
      print("Failed to initialize SDK: ${e.message}");
      return false;
    }
  }

   // Set up the method call handler to receive events from Android
  static void _setupMethodHandler() {
    _channel.setMethodCallHandler((MethodCall call) async {
      print('Received from Android: ${call.method}');
      print('Arguments: ${call.arguments}');

      switch (call.method) {
        case 'onNFCSessionStart':
          print('NFC Session Started');
          if (onNFCSessionStart != null) {
            onNFCSessionStart!();
          }
          break;

        case 'onNFCSessionFinish':
          print('NFC Session Finished');
          if (onNFCSessionFinish != null) {
            onNFCSessionFinish!();
          }
          break;

        case 'onPassportDataRead':
          print('Passport Data Received!');
          final data = call.arguments as Map<dynamic, dynamic>;
  
          if (onPassportDataRead != null) {
            onPassportDataRead!(data);
          }
          break;

        case 'onNFCError':
          print('NFC Error: ${call.arguments}');
          if (onNFCError != null) {
            onNFCError!(call.arguments.toString());
          }
          break;

        case 'onAccessDenied':
          print('Access Denied: ${call.arguments}');
          if (onAccessDenied != null) {
            onAccessDenied!(call.arguments.toString());
          }
          break;

        case 'onBACDenied':
          print('BAC Denied: ${call.arguments}');
          if (onBACDenied != null) {
            onBACDenied!(call.arguments.toString());
          }
          break;

        case 'onPACEError':
          print('PACE Error: ${call.arguments}');
          if (onPACEError != null) {
            onPACEError!(call.arguments.toString());
          }
          break;

        case 'onCardError':
          print('Card Error: ${call.arguments}');
          if (onCardError != null) {
            onCardError!(call.arguments.toString());
          }
          break;

        default:
          print('Unknown method: ${call.method}');
      }

      return null;
    });

    print('✅ AlgerianIdSdk method handler initialized');
  }


  static Future<String> getVersion() async {
    return await _channel.invokeMethod('getVersion');
  }

  static Future<bool> isNFCSupported() async {
    return await _channel.invokeMethod('isNFCSupported');
  }

  static Future<bool> isNFCEnabled() async {
    return await _channel.invokeMethod('isNFCEnabled');
  }

  static Future<bool> setMRZInfoForNFC(Map<String, String> mrzData) async {
    return await _channel.invokeMethod('setMRZInfoForNFC', mrzData);
  }

  static Future<bool> checkDependencies() async {
    return await _channel.invokeMethod('checkDependencies');
  }

  static Future<bool> dispose() async {
    return await _channel.invokeMethod('dispose');
  }

  // MRZ Processing methods
  static Future<String> cleanMRZString(String mrzString) async {
    return await _channel.invokeMethod('cleanMRZString', {
      'mrzString': mrzString,
    });
  }

  static Future<bool> isValidMRZFormat(String text) async {
    return await _channel.invokeMethod('isValidMRZFormat', {'text': text});
  }

  static Future<bool> validateMRZData(Map<String, String> mrzData) async {
    return await _channel.invokeMethod('validateMRZData', mrzData);
  }

  static Future<String> getDocumentType(Map<String, String> mrzData) async {
    return await _channel.invokeMethod('getDocumentType', mrzData);
  }

  static Future<Map<dynamic, dynamic>> extractPersonalInfo(
    Map<String, String> mrzData,
  ) async {
    return await _channel.invokeMethod('extractPersonalInfo', mrzData);
  }

  static Future<Map<dynamic, dynamic>> processMRZLines({
    required String line1,
    required String line2,
    String? line3,
  }) async {
    final args = {
      'line1': line1,
      'line2': line2,
      if (line3 != null) 'line3': line3,
    };
    return await _channel.invokeMethod('processMRZLines', args);
  }

  // NFC Methods (to be implemented based on your NFC workflow)
  static Future<bool> handleNFCTag() async {
    return await _channel.invokeMethod('handleNFCTag');
  }

  static Future<bool> prepareNFCReading(Map<String, String> mrzData) async {
    return await _channel.invokeMethod('setMRZInfoForNFC', mrzData);
  }

  // Simple MRZ validation
  static Future<bool> quickValidateMRZ(
    String line1,
    String line2, [
    String? line3,
  ]) async {
    try {
      final result = await processMRZLines(
        line1: line1,
        line2: line2,
        line3: line3,
      );
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Quick document info extraction
  static Future<Map<String, dynamic>?> extractDocumentInfo(
    String line1,
    String line2, [
    String? line3,
  ]) async {
    try {
      final result = await processMRZLines(
        line1: line1,
        line2: line2,
        line3: line3,
      );
      if (result['success'] == true) {
        return Map<String, dynamic>.from(result['mrzInfo']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  // =============================================
  // NEW OCR METHODS - Add these below
  // =============================================

  /// Detect text from bitmap image
  static Future<Map<dynamic, dynamic>> detectTextFromBitmap({
    required Uint8List bitmapBytes,
    int rotation = 0,
  }) async {
    try {
      return await _channel.invokeMethod('detectTextFromBitmap', {
        'bitmapBytes': bitmapBytes,
        'rotation': rotation,
      });
    } catch (e) {
      return {'success': false, 'error': 'Failed to process bitmap: $e'};
    }
  }

  /// Quick MRZ detection from bitmap
  /// [bitmapBytes] - Byte array of the bitmap image
  static Future<Map<dynamic, dynamic>> detectMRZFromBitmap({
    required Uint8List bitmapBytes,
  }) async {
    try {
      return await _channel.invokeMethod('detectMRZFromBitmap', {
        'bitmapBytes': bitmapBytes,
      });
    } catch (e) {
      return {'success': false, 'error': 'Failed to detect MRZ: $e'};
    }
  }

  /// Detect text from camera frame data
  /// [frameData] - Raw frame data (usually NV21 format)
  /// [width] - Frame width
  /// [height] - Frame height
  /// [rotation] - Frame rotation
  static Future<Map<dynamic, dynamic>> detectTextFromFrame({
    required Uint8List frameData,
    required int width,
    required int height,
    int rotation = 0,
  }) async {
    try {
      return await _channel.invokeMethod('detectTextFromFrame', {
        'frameData': frameData,
        'width': width,
        'height': height,
        'rotation': rotation,
      });
    } catch (e) {
      return {'success': false, 'error': 'Failed to process frame: $e'};
    }
  }

  /// Detect text from byte data (NV21 format)
  /// [byteData] - Raw byte data in NV21 format
  /// [width] - Image width
  /// [height] - Image height
  /// [rotation] - Image rotation
  static Future<Map<dynamic, dynamic>> detectTextFromByteData({
    required Uint8List byteData,
    required int width,
    required int height,
    int rotation = 0,
  }) async {
    try {
      return await _channel.invokeMethod('detectTextFromByteData', {
        'byteData': byteData,
        'width': width,
        'height': height,
        'rotation': rotation,
      });
    } catch (e) {
      return {'success': false, 'error': 'Failed to process byte data: $e'};
    }
  }

  /// Convenience method to detect MRZ from image file
  /// [imageFile] - File object of the image
  static Future<Map<dynamic, dynamic>> detectMRZFromImageFile({
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await detectMRZFromBitmap(bitmapBytes: bytes);
    } catch (e) {
      return {'success': false, 'error': 'Failed to read image file: $e'};
    }
  }

  /// Convenience method to detect MRZ from asset image
  /// [assetPath] - Path to the asset image
  static Future<Map<dynamic, dynamic>> detectMRZFromAsset({
    required String assetPath,
  }) async {
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      return await detectMRZFromBitmap(bitmapBytes: bytes);
    } catch (e) {
      return {'success': false, 'error': 'Failed to load asset: $e'};
    }
  }

  /// Check if OCR features are available
  static Future<bool> isOCRAvailable() async {
    try {
      final result = await _channel.invokeMethod('checkDependencies');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Quick OCR status check
  static Future<Map<String, dynamic>> getOCRStatus() async {
    try {
      final isAvailable = await isOCRAvailable();
      final version = await getVersion();

      return {
        'available': isAvailable,
        'version': version,
        'features': ['bitmap_ocr', 'frame_ocr', 'mrz_detection'],
        'status': isAvailable ? 'ready' : 'unavailable',
      };
    } catch (e) {
      return {
        'available': false,
        'version': 'unknown',
        'features': [],
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}
