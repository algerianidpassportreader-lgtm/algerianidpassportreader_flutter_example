package com.algerianidpassportreader.testappflutter //change with your package 

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import com.google.mlkit.vision.text.Text
import com.yaakoubdjabidev.algerianidpassportreader.AlgerianIDPassportSDK
import com.yaakoubdjabidev.algerianidpassportreader.data.Passport
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.jmrtd.lds.icao.MRZInfo
import org.json.JSONObject
import net.sf.scuba.data.Gender
import io.fotoapparat.preview.Frame
import io.fotoapparat.parameter.Resolution
import kotlinx.coroutines.runBlocking

class AlgerianIdSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private var context: Context? = null
    private var sdk: AlgerianIDPassportSDK? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "algerian_id_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        sdk = context?.let { AlgerianIDPassportSDK(it) }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
        "initializeWithToken" -> handleInitializeWithToken(call, result)
        "initialize" -> handleInitialize(result) 
        "getTokenStatus" -> handleGetTokenStatus(result)

            // Basic SDK methods
            "getVersion" -> handleGetVersion(result)
            "checkDependencies" -> handleCheckDependencies(result)
            "isNFCSupported" -> handleIsNFCSupported(result)
            "isNFCEnabled" -> handleIsNFCEnabled(result)
            "dispose" -> handleDispose(result)
            
            // MRZ Processing methods
            "cleanMRZString" -> handleCleanMRZString(call, result)
            "isValidMRZFormat" -> handleIsValidMRZFormat(call, result)
            "validateMRZData" -> handleValidateMRZData(call, result)
            "getDocumentType" -> handleGetDocumentType(call, result)
            "extractPersonalInfo" -> handleExtractPersonalInfo(call, result)
            "processMRZLines" -> handleProcessMRZLines(call, result)
            "setMRZInfoForNFC" -> handleSetMRZInfoForNFC(call, result)
            
            // NFC Methods
            "handleNFCTag" -> handleHandleNFCTag(call, result)
            "startNFCReading" -> handleStartNFCReading(result)
            "stopNFCReading" -> handleStopNFCReading(result)


            // Passport Data Methods
            "extractCompletePersonalInfo" -> handleExtractCompletePersonalInfo(call, result)
            "getVerificationStatus" -> handleGetVerificationStatus(call, result)
            "isPassportDataComplete" -> handleIsPassportDataComplete(call, result)
        
        // OCR METHODS 
        "detectTextFromBitmap" -> handleDetectTextFromBitmap(call, result)
        "detectTextFromFrame" -> handleDetectTextFromFrame(call, result)
        "detectTextFromImage" -> handleDetectTextFromImage(call, result)
        "detectTextFromInputImage" -> handleDetectTextFromInputImage(call, result)
        "detectTextFromByteData" -> handleDetectTextFromByteData(call, result)
        "detectMRZFromBitmap" -> handleDetectMRZFromBitmap(call, result)

            
            else -> result.notImplemented()
        }
    }

    // Basic SDK methods
    private fun handleGetVersion(result: Result) {
        try {
            val version = AlgerianIDPassportSDK.getVersion()
            result.success(version)
        } catch (e: Exception) {
            result.error("VERSION_ERROR", e.message, null)
        }
    }

    private fun handleCheckDependencies(result: Result) {
        try {
            val dependenciesOk = AlgerianIDPassportSDK.checkDependencies()
            result.success(dependenciesOk)
        } catch (e: Exception) {
            result.error("DEPENDENCIES_ERROR", e.message, null)
        }
    }

    private fun handleIsNFCSupported(result: Result) {
        try {
            val supported = sdk?.isNFCSupported() ?: false
            result.success(supported)
        } catch (e: Exception) {
            result.error("NFC_ERROR", e.message, null)
        }
    }

    private fun handleIsNFCEnabled(result: Result) {
        try {
            val enabled = sdk?.isNFCEnabled() ?: false
            result.success(enabled)
        } catch (e: Exception) {
            result.error("NFC_ERROR", e.message, null)
        }
    }

    private fun handleDispose(result: Result) {
        try {
            sdk?.dispose()
            result.success(true)
        } catch (e: Exception) {
            result.error("DISPOSE_ERROR", e.message, null)
        }
    }

    // MRZ Processing methods
    private fun handleCleanMRZString(call: MethodCall, result: Result) {
        try {
            val mrzString = call.argument<String>("mrzString") ?: ""
            val cleaned = sdk?.cleanMRZString(mrzString) ?: ""
            result.success(cleaned)
        } catch (e: Exception) {
            result.error("CLEAN_MRZ_ERROR", e.message, null)
        }
    }

    private fun handleIsValidMRZFormat(call: MethodCall, result: Result) {
        try {
            val text = call.argument<String>("text") ?: ""
            val isValid = sdk?.isValidMRZFormat(text) ?: false
            result.success(isValid)
        } catch (e: Exception) {
            result.error("VALIDATE_FORMAT_ERROR", e.message, null)
        }
    }

    private fun handleValidateMRZData(call: MethodCall, result: Result) {
        try {
            val mrzData = call.arguments as? Map<String, String>
            if (mrzData != null) {
                val mrzInfo = createMRZInfoFromMap(mrzData)
                val isValid = sdk?.validateMRZData(mrzInfo) ?: false
                result.success(isValid)
            } else {
                result.error("VALIDATE_DATA_ERROR", "Invalid MRZ data", null)
            }
        } catch (e: Exception) {
            result.error("VALIDATE_DATA_ERROR", e.message, null)
        }
    }

    private fun handleGetDocumentType(call: MethodCall, result: Result) {
        try {
            val mrzData = call.arguments as? Map<String, String>
            if (mrzData != null) {
                val mrzInfo = createMRZInfoFromMap(mrzData)
                val docType = sdk?.getDocumentType(mrzInfo) ?: "UNKNOWN"
                result.success(docType)
            } else {
                result.error("DOC_TYPE_ERROR", "Invalid MRZ data", null)
            }
        } catch (e: Exception) {
            result.error("DOC_TYPE_ERROR", e.message, null)
        }
    }

    private fun handleExtractPersonalInfo(call: MethodCall, result: Result) {
        try {
            val mrzData = call.arguments as? Map<String, String>
            if (mrzData != null) {
                val mrzInfo = createMRZInfoFromMap(mrzData)
                val personalInfo = sdk?.extractPersonalInfo(mrzInfo) ?: emptyMap()
                result.success(personalInfo)
            } else {
                result.error("EXTRACT_INFO_ERROR", "Invalid MRZ data", null)
            }
        } catch (e: Exception) {
            result.error("EXTRACT_INFO_ERROR", e.message, null)
        }
    }

    private fun handleProcessMRZLines(call: MethodCall, result: Result) {
        try {
            val line1 = call.argument<String>("line1") ?: ""
            val line2 = call.argument<String>("line2") ?: ""
            val line3 = call.argument<String>("line3")
            
            sdk?.processMRZLines(line1, line2, line3, object : AlgerianIDPassportSDK.MRZDetectionCallback {
                override fun onMRZDetected(mrzInfo: MRZInfo) {
                    val mrzMap = mapOf(
                        "documentNumber" to mrzInfo.documentNumber,
                        "dateOfBirth" to mrzInfo.dateOfBirth,
                        "dateOfExpiry" to mrzInfo.dateOfExpiry,
                        "nationality" to mrzInfo.nationality,
                        "gender" to mrzInfo.gender.toString(),
                        "issuingState" to mrzInfo.issuingState,
                        "primaryIdentifier" to mrzInfo.primaryIdentifier,
                        "secondaryIdentifier" to (mrzInfo.secondaryIdentifier ?: ""),
                        "documentCode" to mrzInfo.documentCode
                    )
                    result.success(mapOf("success" to true, "mrzInfo" to mrzMap))
                }

                override fun onMRZDetectionFailed(error: String) {
                    result.success(mapOf("success" to false, "error" to error))
                }

                override fun onMRZDetectionError(exception: Exception) {
                    result.error("PROCESS_MRZ_ERROR", exception.message, null)
                }
            })
        } catch (e: Exception) {
            result.error("PROCESS_MRZ_ERROR", e.message, null)
        }
    }

    private fun handleSetMRZInfoForNFC(call: MethodCall, result: Result) {
        try {
            val mrzData = call.arguments as? Map<String, String>
            if (mrzData != null) {
                val mrzInfo = createMRZInfoFromMap(mrzData)
                sdk?.setMRZInfoForNFC(mrzInfo)
                result.success(true)
            } else {
                result.error("SET_MRZ_NFC_ERROR", "Invalid MRZ data", null)
            }
        } catch (e: Exception) {
            result.error("SET_MRZ_NFC_ERROR", e.message, null)
        }
    }

    // NFC Methods
fun handleNfcIntent(intent: Intent?) {
    try {
        val handled = sdk?.handleNFCTag(intent, object : AlgerianIDPassportSDK.NFCReadCallback {
            override fun onNFCSessionStart() {
                channel.invokeMethod("onNFCSessionStart", null)
            }

            override fun onNFCSessionFinish() {
                channel.invokeMethod("onNFCSessionFinish", null)
            }

            override fun onPassportDataRead(passport: Passport?) {
                val passportData = sdk?.extractCompletePersonalInfo(passport)
                channel.invokeMethod("onPassportDataRead", passportData)
            }

            override fun onNFCError(error: Exception) {
                channel.invokeMethod("onNFCError", error.message)
            }

            override fun onAccessDenied(exception: Exception) {
                channel.invokeMethod("onAccessDenied", exception.message)
            }

            override fun onBACDenied(exception: Exception) {
                channel.invokeMethod("onBACDenied", exception.message)
            }

            override fun onPACEError(exception: Exception) {
                channel.invokeMethod("onPACEError", exception.message)
            }

            override fun onCardError(exception: Exception) {
                channel.invokeMethod("onCardError", exception.message)
            }
        }) ?: false
        
    } catch (e: Exception) {
        channel.invokeMethod("onNFCError", "NFC error: ${e.message}")
    }
}
    private fun handleHandleNFCTag(call: MethodCall, result: Result) {
        try {
            // This would need to be called from MainActivity when NFC intent is received
            result.notImplemented()
        } catch (e: Exception) {
            result.error("HANDLE_NFC_ERROR", e.message, null)
        }
    }
private fun handleStartNFCReading(result: Result) {
    try {
        result.success(true)
    } catch (e: Exception) {
        result.error("NFC_START_ERROR", e.message, null)
    }
}

private fun handleStopNFCReading(result: Result) {
    try {
        result.success(true)
    } catch (e: Exception) {
        result.error("NFC_STOP_ERROR", e.message, null)
    }
}


    // Passport Data Methods
    private fun handleExtractCompletePersonalInfo(call: MethodCall, result: Result) {
        try {
            result.notImplemented()
        } catch (e: Exception) {
            result.error("EXTRACT_COMPLETE_INFO_ERROR", e.message, null)
        }
    }

    private fun handleGetVerificationStatus(call: MethodCall, result: Result) {
        try {
            result.notImplemented()
        } catch (e: Exception) {
            result.error("VERIFICATION_STATUS_ERROR", e.message, null)
        }
    }

    private fun handleIsPassportDataComplete(call: MethodCall, result: Result) {
        try {
            result.notImplemented()
        } catch (e: Exception) {
            result.error("PASSPORT_COMPLETE_ERROR", e.message, null)
        }
    }


/**
 * Detect MRZ from Bitmap image
 */
private fun handleDetectTextFromBitmap(call: MethodCall, result: Result) {
    try {
        val bitmapBytes = call.argument<ByteArray>("bitmapBytes")
        val rotation = call.argument<Int>("rotation") ?: 0
        
        if (bitmapBytes == null) {
            result.error("BITMAP_ERROR", "Bitmap data is null", null)
            return
        }
        
        val bitmap = BitmapFactory.decodeByteArray(bitmapBytes, 0, bitmapBytes.size)
        
        sdk?.detectOCRTextFromBitmap(bitmap, object : AlgerianIDPassportSDK.TextDetectionCallback {
            override fun onTextDetected(text: String) {
                result.success(mapOf(
                    "success" to true,
                    "text" to text  // Returns all OCR text
                ))
            }

            override fun onTextDetectionFailed(error: String) {
                result.success(mapOf(
                    "success" to false,
                    "error" to error
                ))
            }

            override fun onTextDetectionError(exception: Exception) {
                result.error("OCR_ERROR", exception.message, null)
            }
        })
    } catch (e: Exception) {
        result.error("BITMAP_PROCESSING_ERROR", e.message, null)
    }
}
/**
 * Quick MRZ detection from bitmap 
 */
private fun handleDetectMRZFromBitmap(call: MethodCall, result: Result) {
    try {
        val bitmapBytes = call.argument<ByteArray>("bitmap")
        
        if (bitmapBytes == null) {
            result.error("BITMAP_ERROR", "Bitmap data is null", null)
            return
        }
        
        val bitmap = BitmapFactory.decodeByteArray(bitmapBytes, 0, bitmapBytes.size)
        
        sdk?.detectMRZFromBitmap(bitmap) { mrzInfo, error ->
            if (mrzInfo != null) {
                val mrzMap = convertMRZInfoToMap(mrzInfo)
                result.success(mapOf("success" to true, "mrzInfo" to mrzMap))
            } else {
                result.success(mapOf("success" to false, "error" to error))
            }
        }
    } catch (e: Exception) {
        result.error("QUICK_OCR_ERROR", e.message, null)
    }
}

/**
 * Detect MRZ from camera Frame data
 */
private fun handleDetectTextFromFrame(call: MethodCall, result: Result) {
    try {
        val frameData = call.argument<ByteArray>("frameData")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rotation = call.argument<Int>("rotation") ?: 0
        
        if (frameData == null || width == 0 || height == 0) {
            result.error("FRAME_ERROR", "Invalid frame data", null)
            return
        }
        
        // Create Frame object (you might need to adjust based on your Frame class)
        val frame = Frame(
            size = Resolution(width, height),
            image = frameData,
            rotation = 0 // Rotation is handled separately
        )
        
        sdk?.detectTextFromFrame(frame, rotation, object : AlgerianIDPassportSDK.MRZDetectionCallback {
            override fun onMRZDetected(mrzInfo: MRZInfo) {
                val mrzMap = convertMRZInfoToMap(mrzInfo)
                result.success(mapOf("success" to true, "mrzInfo" to mrzMap))
            }

            override fun onMRZDetectionFailed(error: String) {
                result.success(mapOf("success" to false, "error" to error))
            }

            override fun onMRZDetectionError(exception: Exception) {
                result.error("FRAME_OCR_ERROR", exception.message, null)
            }
        })
    } catch (e: Exception) {
        result.error("FRAME_PROCESSING_ERROR", e.message, null)
    }
}

/**
 * Detect MRZ from Media.Image (for camera preview)
 */
private fun handleDetectTextFromImage(call: MethodCall, result: Result) {
    try {
        result.notImplemented()
    } catch (e: Exception) {
        result.error("IMAGE_PROCESSING_ERROR", e.message, null)
    }
}

/**
 * Detect MRZ from InputImage (flexible input)
 */
private fun handleDetectTextFromInputImage(call: MethodCall, result: Result) {
    try {
        result.notImplemented()
    } catch (e: Exception) {
        result.error("INPUT_IMAGE_ERROR", e.message, null)
    }
}

/**
 * Detect MRZ from raw byte data (NV21 format)
 */
private fun handleDetectTextFromByteData(call: MethodCall, result: Result) {
    try {
        val byteData = call.argument<ByteArray>("byteData")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rotation = call.argument<Int>("rotation") ?: 0
        
        if (byteData == null || width == 0 || height == 0) {
            result.error("BYTE_DATA_ERROR", "Invalid byte data", null)
            return
        }
        
        sdk?.detectTextFromByteData(byteData, width, height, rotation, 
            object : AlgerianIDPassportSDK.MRZDetectionCallback {
                override fun onMRZDetected(mrzInfo: MRZInfo) {
                    val mrzMap = convertMRZInfoToMap(mrzInfo)
                    result.success(mapOf("success" to true, "mrzInfo" to mrzMap))
                }

                override fun onMRZDetectionFailed(error: String) {
                    result.success(mapOf("success" to false, "error" to error))
                }

                override fun onMRZDetectionError(exception: Exception) {
                    result.error("BYTE_OCR_ERROR", exception.message, null)
                }
            })
    } catch (e: Exception) {
        result.error("BYTE_PROCESSING_ERROR", e.message, null)
    }
}
// ===== TOKEN HANDLERS =====

private fun handleInitializeWithToken(call: MethodCall, result: Result) {
    try {
        val token = call.argument<String>("userToken") ?: ""
        
        if (token.isEmpty()) {
            result.error("INIT_ERROR", "Token cannot be empty", null)
            return
        }
        
        runBlocking {
            try {
                sdk = context?.let { AlgerianIDPassportSDK(it) }
                sdk?.initialize(token)
                result.success(true)
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.message, null)
            }
        }
    } catch (e: Exception) {
        result.error("INIT_ERROR", "Failed to initialize: ${e.message}", null)
    }
}

private fun handleInitialize(result: Result) {
    result.success(true)
}

private fun handleGetTokenStatus(result: Result) {
    runBlocking {
        try {
            val status = sdk?.getTokenStatus()
            // Convert to map 
            val statusMap = mapOf(
                "hasValidToken" to (status?.hasValidToken ?: false),
                "message" to (status?.message ?: "Token status unknown"),
                "email" to (status?.email ?: ""),
                "name" to (status?.name ?: ""),
                "subscriptionEnd" to (status?.subscriptionEnd?.toString() ?: ""),
                "isForever" to (status?.isForever ?: false)
            )
            result.success(statusMap)
        } catch (e: Exception) {
            result.error("TOKEN_STATUS_ERROR", e.message, null)
        }
    }
}

// Helper method to convert MRZInfo to Map 
private fun convertMRZInfoToMap(mrzInfo: MRZInfo): Map<String, String> {
    return mapOf(
        "documentNumber" to mrzInfo.documentNumber,
        "dateOfBirth" to mrzInfo.dateOfBirth,
        "dateOfExpiry" to mrzInfo.dateOfExpiry,
        "nationality" to mrzInfo.nationality,
        "gender" to mrzInfo.gender.toString(),
        "issuingState" to mrzInfo.issuingState,
        "primaryIdentifier" to mrzInfo.primaryIdentifier,
        "secondaryIdentifier" to (mrzInfo.secondaryIdentifier ?: ""),
        "documentCode" to mrzInfo.documentCode
    )
}

    

// Helper method to create MRZInfo from map
    private fun createMRZInfoFromMap(mrzData: Map<String, String>): MRZInfo {
        val gender = when (mrzData["gender"]
        // ?.uppercase()
        ) {
        "M", "MALE" -> Gender.MALE
        "F", "FEMALE" -> Gender.FEMALE
        else -> Gender.UNSPECIFIED
    }

        return MRZInfo(
            mrzData["documentCode"] ?: "",
            mrzData["issuingState"] ?: "",
            mrzData["primaryIdentifier"] ?: "",
            mrzData["secondaryIdentifier"] ?: "",
            mrzData["documentNumber"] ?: "",
            mrzData["nationality"] ?: "",
            mrzData["dateOfBirth"] ?: "",
            gender, // Default to unknown gender
            mrzData["dateOfExpiry"] ?: "",
            mrzData["optionalData"] ?: ""
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        sdk?.dispose()
    }
}