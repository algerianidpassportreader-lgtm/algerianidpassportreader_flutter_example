import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:aaaa_project/constants.dart';
import 'package:aaaa_project/models/mrz_info_model.dart';
import 'package:aaaa_project/services/algerian_id_sdk.dart';

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key, required this.mrzInfoModel});
  final MrzInfoModel mrzInfoModel;
  @override
  _NfcScreenState createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  String sdkVersion = 'Unknown';
  bool nfcSupported = false;
  bool nfcEnabled = false;
  String nfcStatus = 'Ready';
  Map<dynamic, dynamic>? passportData;
  Uint8List? faceImage;
  Uint8List? signatureImage;

  @override
  void initState() {
    super.initState();
    checkSDK();
    _setupNFCListeners();
  }

  void _setupNFCListeners() {
    AlgerianIdSdk.onNFCSessionStart = () {
      setState(() {
        nfcStatus = 'NFC Session Started...';
      });
    };

    AlgerianIdSdk.onNFCSessionFinish = () {
      setState(() {
        nfcStatus = 'NFC Session Finished';
      });
    };

    AlgerianIdSdk.onPassportDataRead = (data) {
      setState(() {
        nfcStatus = 'Passport Data Read Successfully!';
        passportData = data;

        // Decode base64 images
        if (data['faceImage'] != null) {
          try {
            // Clean the base64 string
            String cleanFaceBase64 = data['faceImage'].toString().trim();
            // Remove any potential data URI prefix
            if (cleanFaceBase64.contains(',')) {
              cleanFaceBase64 = cleanFaceBase64.split(',').last;
            }

            faceImage = base64.decode(cleanFaceBase64);
          } catch (e) {
            print('Error decoding face image: $e');
          }
        } else {
          print('No face image data received');
        }

        if (data['signatureImage'] != null) {
          try {
            // Clean the base64 string
            String cleanSignatureBase64 = data['signatureImage']
                .toString()
                .trim();
            // Remove any potential data URI prefix
            if (cleanSignatureBase64.contains(',')) {
              cleanSignatureBase64 = cleanSignatureBase64.split(',').last;
            }

            signatureImage = base64.decode(cleanSignatureBase64);
          } catch (e) {
            print('Error decoding signature image: $e');
          }
        } else {
          print('No signature image data received');
        }
      });
      print('Passport Data: $data');
    };
    AlgerianIdSdk.onNFCError = (error) {
      setState(() {
        nfcStatus = 'NFC Error: $error';
      });
    };

    AlgerianIdSdk.onAccessDenied = (error) {
      setState(() {
        nfcStatus = 'Access Denied: $error';
      });
    };

    AlgerianIdSdk.onBACDenied = (error) {
      setState(() {
        nfcStatus = 'BAC Denied: $error';
      });
    };

    AlgerianIdSdk.onPACEError = (error) {
      setState(() {
        nfcStatus = 'PACE Error: $error';
      });
    };

    AlgerianIdSdk.onCardError = (error) {
      setState(() {
        nfcStatus = 'Card Error: $error';
      });
    };
  }

  Future<void> checkSDK() async {
    try {
      final version = await AlgerianIdSdk.getVersion();
      final supported = await AlgerianIdSdk.isNFCSupported();
      final enabled = await AlgerianIdSdk.isNFCEnabled();

      setState(() {
        sdkVersion = version;
        nfcSupported = supported;
        nfcEnabled = enabled;
      });
    } catch (e) {
      print('SDK Error: $e');
    }
  }

  Future<void> prepareNFC() async {
    try {
      await AlgerianIdSdk.setMRZInfoForNFC(widget.mrzInfoModel.toJson());
      setState(() {
        nfcStatus = 'Ready - Tap your ID card to NFC reader';
      });
    } catch (e) {
      setState(() {
        nfcStatus = 'Error preparing NFC: $e';
      });
    }
  }

  Widget _buildDataItem(String title, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    String title,
    Uint8List? imageData, {
    double height = 150,
  }) {
    if (imageData == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Image.memory(
            imageData,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Error loading image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.str_primary_color,
        title: Text("NFC Reader", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SDK Info Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDK Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildDataItem('SDK Version', sdkVersion),
                    // Add this right after the personal information section
                    _buildDataItem(
                      'Has Face Image',
                      passportData?['hasFaceImage'],
                    ),
                    _buildDataItem(
                      'Has Signature',
                      passportData?['hasSignature'],
                    ),
                    _buildDataItem(
                      'NFC Supported',
                      nfcSupported ? 'Yes' : 'No',
                    ),
                    _buildDataItem('NFC Enabled', nfcEnabled ? 'Yes' : 'No'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // NFC Status Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          nfcStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(nfcStatus),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Passport Data Section
            if (passportData != null && passportData!.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passport Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Display Images
                      _buildImageSection('Face Photo', faceImage, height: 200),
                      _buildImageSection(
                        'Signature',
                        signatureImage,
                        height: 100,
                      ),

                      // Personal Information
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildDataItem(
                        'Document Number',
                        passportData!['documentNumber'],
                      ),
                      _buildDataItem(
                        'Document Type',
                        passportData!['documentType'],
                      ),
                      _buildDataItem(
                        'Issuing State',
                        passportData!['issuingState'],
                      ),
                      _buildDataItem(
                        'Nationality',
                        passportData!['nationality'],
                      ),
                      _buildDataItem(
                        'First Name',
                        passportData!['primaryIdentifier'],
                      ),
                      _buildDataItem(
                        'Last Name',
                        passportData!['secondaryIdentifier'],
                      ),
                      _buildDataItem(
                        'Date of Birth',
                        passportData!['dateOfBirth'],
                      ),
                      _buildDataItem(
                        'Expiry Date',
                        passportData!['dateOfExpiry'],
                      ),
                      _buildDataItem('Gender', passportData!['gender']),

                      // Additional Information
                      if (passportData!['fullDateOfBirth'] != null)
                        _buildDataItem(
                          'Full Date of Birth',
                          passportData!['fullDateOfBirth'],
                        ),
                      if (passportData!['personalNumber'] != null)
                        _buildDataItem(
                          'Personal Number',
                          passportData!['personalNumber'],
                        ),
                      if (passportData!['placeOfBirth'] != null)
                        _buildDataItem(
                          'Place of Birth',
                          passportData!['placeOfBirth'],
                        ),
                      if (passportData!['profession'] != null)
                        _buildDataItem(
                          'Profession',
                          passportData!['profession'],
                        ),
                      if (passportData!['telephone'] != null)
                        _buildDataItem('Telephone', passportData!['telephone']),
                      if (passportData!['title'] != null)
                        _buildDataItem('Title', passportData!['title']),
                      if (passportData!['permanentAddress'] != null)
                        _buildDataItem(
                          'Address',
                          passportData!['permanentAddress'],
                        ),

                      // Verification Status
                      SizedBox(height: 16),
                      Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildDataItem(
                        'Chip Authentication',
                        passportData!['chipAuthentication'],
                      ),
                      _buildDataItem(
                        'Document Signing',
                        passportData!['documentSigning'],
                      ),
                      _buildDataItem(
                        'Country Signing',
                        passportData!['countrySigning'],
                      ),
                      _buildDataItem(
                        'Hash Verification',
                        passportData!['hashVerification'],
                      ),

                      // Features
                      SizedBox(height: 16),
                      Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildDataItem('Has BAC', passportData!['hasBAC']),
                      _buildDataItem('Has AA', passportData!['hasAA']),
                      _buildDataItem('Has EAC', passportData!['hasEAC']),
                      _buildDataItem('Has CA', passportData!['hasCA']),

                      // Document Availability
                      SizedBox(height: 16),
                      Text(
                        'Document Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildDataItem(
                        'Has Face Image',
                        passportData!['hasFaceImage'],
                      ),
                      _buildDataItem(
                        'Has Signature',
                        passportData!['hasSignature'],
                      ),
                      _buildDataItem(
                        'Has Fingerprints',
                        passportData!['hasFingerprints'],
                      ),
                      _buildDataItem(
                        'Has Additional Details',
                        passportData!['hasAdditionalDetails'],
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (passportData == null) ...[
              // Empty state when no data
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.contactless_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Passport Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Prepare NFC reading and tap your ID card to display data',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 16),

            // Buttons Section
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: prepareNFC,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Prepare NFC Reading',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Clear Data Button
            if (passportData != null) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    passportData = null;
                    faceImage = null;
                    signatureImage = null;
                    nfcStatus = 'Ready';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Clear Data',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Error') || status.contains('Denied')) {
      return Colors.red;
    } else if (status.contains('Success')) {
      return Colors.green;
    } else if (status.contains('Started') || status.contains('Ready')) {
      return Colors.orange;
    } else if (status.contains('Finished')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
}
