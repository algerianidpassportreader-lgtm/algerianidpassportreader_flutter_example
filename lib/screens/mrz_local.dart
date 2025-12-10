import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aaaa_project/constants.dart';
import 'package:aaaa_project/helpers/screen_helper.dart';
import 'package:aaaa_project/models/mrz_info_model.dart';
import 'package:aaaa_project/screens/mrz_screen.dart';
import 'package:aaaa_project/screens/nfc_screen.dart';
import 'package:aaaa_project/services/algerian_id_sdk.dart';

class MrzLocal extends StatefulWidget {
  @override
  _MrzLocalState createState() => _MrzLocalState();
}

class _MrzLocalState extends State<MrzLocal> {
  String _testResult = 'Select an image to start';
  bool _isTesting = false;
  Uint8List? _selectedImage;
  String? _imageSource;
  MrzInfoModel? mrzInfoModel;
  String? textDetected;
  Map<dynamic, dynamic>? _lastResult;
  String _detectionType = 'mrz'; // 'mrz' or 'ocr'

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _imageSource = 'Gallery';
          _testResult = 'Image selected from gallery';
          _lastResult = null;
          mrzInfoModel = null;
          textDetected = null;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _takePhotoFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _imageSource = 'Camera';
          _testResult = 'Photo taken from camera';
          _lastResult = null;
          mrzInfoModel = null;
          textDetected = null;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _runMRZDetection() async {
    if (_selectedImage == null) {
      setState(() {
        _testResult = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _detectionType = 'mrz'; // Set type to MRZ
      _testResult = 'Running MRZ detection...';
    });

    try {
      final result = await AlgerianIdSdk.detectMRZFromBitmap(
        bitmapBytes: _selectedImage!,
      );

      print("MRZ Detection Result: $result");

      setState(() {
        _lastResult = result;
        _isTesting = false;
        if (result['success'] == true) {
          mrzInfoModel = MrzInfoModel.fromJson(result['mrzInfo']);
          textDetected = null; // Clear OCR text when doing MRZ
          _testResult = 'MRZ Detection Successful';
        } else {
          _testResult = 'MRZ Detection Failed: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _runOCRDetection() async {
    if (_selectedImage == null) {
      setState(() {
        _testResult = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _detectionType = 'ocr'; // Set type to OCR
      _testResult = 'Running OCR detection...';
    });

    try {
      final result = await AlgerianIdSdk.detectTextFromBitmap(
        bitmapBytes: _selectedImage!,
      );

      print("OCR Detection Result: $result");

      setState(() {
        _lastResult = result;
        _isTesting = false;
        if (result['success'] == true) {
          textDetected = result['text'];
          mrzInfoModel = null; // Clear MRZ when doing OCR
          _testResult = 'OCR Detection Successful';
        } else {
          _testResult = 'OCR Detection Failed: ${result['error']}';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.str_primary_color,
        title: Text(
          "MRZ & OCR Image Detection",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MRZScreen()),
            );
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Selection Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: Icon(
                              Icons.photo_library,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Gallery',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.str_primary_color,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePhotoFromCamera,
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            label: Text(
                              'Camera',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.str_primary_color,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'From $_imageSource',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Detection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting || _selectedImage == null
                        ? null
                        : _runMRZDetection,
                    icon: Icon(Icons.document_scanner, color: Colors.white),
                    label: Text(
                      'Detect MRZ',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.str_primary_color,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting || _selectedImage == null
                        ? null
                        : _runOCRDetection,
                    icon: Icon(Icons.text_fields_outlined, color: Colors.white),
                    label: Text(
                      'Detect OCR',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.str_primary_color,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Status Indicator
            if (_isTesting)
              Column(
                children: [
                  CircularProgressIndicator(color: Constants.str_primary_color),
                  SizedBox(height: 8),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Constants.str_primary_color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult.contains('Successful')
                      ? Colors.green[50]
                      : _testResult.contains('Failed') ||
                            _testResult.contains('Error')
                      ? Colors.red[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testResult.contains('Successful')
                        ? Colors.green[100]!
                        : _testResult.contains('Failed') ||
                              _testResult.contains('Error')
                        ? Colors.red[100]!
                        : Colors.blue[100]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult.contains('Successful')
                          ? Icons.check_circle
                          : _testResult.contains('Failed') ||
                                _testResult.contains('Error')
                          ? Icons.error
                          : Icons.info,
                      color: _testResult.contains('Successful')
                          ? Colors.green
                          : _testResult.contains('Failed') ||
                                _testResult.contains('Error')
                          ? Colors.red
                          : Constants.str_primary_color,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult,
                        style: TextStyle(
                          color: _testResult.contains('Successful')
                              ? Colors.green[800]
                              : _testResult.contains('Failed') ||
                                    _testResult.contains('Error')
                              ? Colors.red[800]
                              : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Results Display
            if (_lastResult != null)
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _detectionType == 'mrz'
                                ? 'MRZ Detection Results'
                                : 'OCR Text Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Constants.str_primary_color,
                            ),
                          ),
                          SizedBox(height: 12),

                          if (_lastResult!['success'] == true)
                            _detectionType == 'mrz'
                                ? _buildMRZResultContent()
                                : _buildOCRResultContent()
                          else
                            SizedBox(
                              width: ScreenHelper.screenWidthPercentage(
                                context,
                                0.8,
                              ),
                              child: Text(
                                'Error: ${_lastResult!['error'] ?? 'Unknown error'}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // NFC Button (only for MRZ results)
            if (_detectionType == 'mrz' && mrzInfoModel != null) ...[
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NfcScreen(mrzInfoModel: mrzInfoModel!),
                          ),
                        );
                      },
                      icon: Icon(Icons.nfc, color: Colors.white),
                      label: Text(
                        'Start NFC Reading',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.str_primary_color,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMRZResultContent() {
    if (mrzInfoModel != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultItem('Document Number', mrzInfoModel?.documentNumber),
          _buildResultItem('Birth Date', mrzInfoModel?.dateOfBirth),
          _buildResultItem('Expiry Date', mrzInfoModel?.dateOfExpiry),
          _buildResultItem('Nationality', mrzInfoModel?.nationality),
          _buildResultItem('Gender', mrzInfoModel?.gender),
          _buildResultItem('Issuing State', mrzInfoModel?.issuingState),
          _buildResultItem('Document Code', mrzInfoModel?.documentCode),
          _buildResultItem(
            'Primary Identifier',
            mrzInfoModel?.primaryIdentifier,
          ),
          _buildResultItem(
            'Secondary Identifier',
            mrzInfoModel?.secondaryIdentifier,
          ),
        ],
      );
    } else {
      return SizedBox(
        width: ScreenHelper.screenWidthPercentage(context, 0.8),
        child: Text(
          'No MRZ data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildOCRResultContent() {
    if (textDetected != null && textDetected!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Text:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              textDetected!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'Text Length: ${textDetected!.length} characters',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      );
    } else {
      return SizedBox(
        width: ScreenHelper.screenWidthPercentage(context, 0.8),
        child: Text('No text detected', style: TextStyle(color: Colors.grey)),
      );
    }
  }

  Widget _buildResultItem(String label, dynamic value) {
    final displayValue = value?.toString() ?? 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              displayValue,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
