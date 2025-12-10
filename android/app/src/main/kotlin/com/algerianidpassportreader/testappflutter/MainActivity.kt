package com.algerianidpassportreader.testappflutter //change with your package 

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import com.yaakoubdjabidev.algerianidpassportreader.AlgerianIDPassportSDK
import com.yaakoubdjabidev.algerianidpassportreader.data.Passport
import org.jmrtd.lds.icao.MRZInfo
import net.sf.scuba.data.Gender
import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import android.graphics.BitmapFactory
import io.fotoapparat.preview.Frame
import io.fotoapparat.parameter.Resolution
import kotlinx.coroutines.runBlocking

class MainActivity: FlutterActivity() {
    private val CHANNEL = "algerian_id_sdk"
    private var flutterEngine: FlutterEngine? = null
    private var nfcAdapter: NfcAdapter? = null
    private var sdk: AlgerianIDPassportSDK? = null
    private var mrzInfo: MRZInfo? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        sdk = AlgerianIDPassportSDK(applicationContext)
        
    
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeWithToken" -> handleInitializeWithToken(call, result)
                "getTokenStatus" -> handleGetTokenStatus(result)
                "getVersion" -> result.success("1.0.0")
                "isNFCSupported" -> result.success(nfcAdapter != null)
                "isNFCEnabled" -> result.success(nfcAdapter?.isEnabled == true)
                "setMRZInfoForNFC" -> {
                    val mrzData = call.arguments as? Map<String, String>
                    if (mrzData != null) {
                        setMrzInfo(mrzData)
                        enableNfcForeground()
                        result.success(true)
                    } else {
                        result.error("MRZ_ERROR", "Invalid MRZ data", null)
                    }
                }
        "detectMRZFromBitmap" -> handleDetectMRZFromBitmap(call, result)
        "detectTextFromBitmap" -> handleDetectTextFromBitmap(call, result)
        "detectTextFromFrame" -> handleDetectTextFromFrame(call, result)
        "detectTextFromByteData" -> handleDetectTextFromByteData(call, result)

                else -> result.notImplemented()
            }
        }
    }

    private fun setMrzInfo(mrzData: Map<String, String>) {
        try {
            val gender = when (mrzData["gender"]) {
                "M", "MALE" -> Gender.MALE
                "F", "FEMALE" -> Gender.FEMALE
                else -> Gender.UNSPECIFIED
            }
            
            mrzInfo = MRZInfo(
                mrzData["documentCode"] ?: "",
                mrzData["issuingState"] ?: "",
                mrzData["primaryIdentifier"] ?: "",
                mrzData["secondaryIdentifier"] ?: "",
                mrzData["documentNumber"] ?: "",
                mrzData["nationality"] ?: "",
                mrzData["dateOfBirth"] ?: "",
                gender,
                mrzData["dateOfExpiry"] ?: "",
                mrzData["optionalData"] ?: ""
            )
            
            // Set MRZ info in the SDK
            sdk?.setMRZInfoForNFC(mrzInfo!!)
            
        } catch (e: Exception) {
            sendToFlutter("onNFCError", "MRZ parsing error: ${e.message}")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        if (mrzInfo != null) {
            enableNfcForeground()
        }
    }

    override fun onPause() {
        super.onPause()
        disableNfcForeground()
    }

    private fun enableNfcForeground() {
        nfcAdapter?.let { adapter ->
            val intent = Intent(this, javaClass).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                this, 0, intent, 
                android.app.PendingIntent.FLAG_MUTABLE
            )
            
            val techLists = arrayOf(arrayOf(IsoDep::class.java.name))
            adapter.enableForegroundDispatch(this, pendingIntent, null, techLists)
        }
    }

    private fun disableNfcForeground() {
        nfcAdapter?.disableForegroundDispatch(this)
    }

    private fun handleNfcIntent(intent: Intent) {
        val action = intent.action
        if (NfcAdapter.ACTION_TECH_DISCOVERED == action) {
            val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            if (tag != null) {
                processNFCTag(tag)
            }
        }
    }

    private fun processNFCTag(tag: Tag) {
        try {
            if (mrzInfo == null) {
                sendToFlutter("onNFCError", "MRZ info not set. Call setMRZInfoForNFC first.")
                return
            }

            // Create a mock intent with the tag for your SDK
            val intent = Intent().apply {
                putExtra(NfcAdapter.EXTRA_TAG, tag)
            }

            sdk?.handleNFCTag(intent, object : AlgerianIDPassportSDK.NFCReadCallback {
                override fun onNFCSessionStart() {
                    sendToFlutter("onNFCSessionStart", null)
                }

                override fun onNFCSessionFinish() {
                    sendToFlutter("onNFCSessionFinish", null)
                }

                override fun onPassportDataRead(passport: Passport?) {
    val passportData = sdk?.extractCompletePersonalInfo(passport)
    
    
    // Convert Bitmap images to base64 
    val faceImageBase64 = passport?.face?.let { faceBitmap ->
        val base64 = convertBitmapToBase64(faceBitmap)
        base64
    }
    val signatureImageBase64 = passport?.signature?.let { signatureBitmap ->
        val base64 = convertBitmapToBase64(signatureBitmap)
        base64
    }
    
    // Add image data to passport data
    val passportDataWithImages = mutableMapOf<String, Any?>()
    passportData?.let { passportDataWithImages.putAll(it) }
    faceImageBase64?.let { passportDataWithImages["faceImage"] = it }
    signatureImageBase64?.let { passportDataWithImages["signatureImage"] = it }
    
    sendToFlutter("onPassportDataRead", passportDataWithImages)
}

                override fun onNFCError(error: Exception) {
                    sendToFlutter("onNFCError", error.message)
                }

                override fun onAccessDenied(exception: Exception) {
                    sendToFlutter("onAccessDenied", exception.message)
                }

                override fun onBACDenied(exception: Exception) {
                    sendToFlutter("onBACDenied", exception.message)
                }

                override fun onPACEError(exception: Exception) {
                    sendToFlutter("onPACEError", exception.message)
                }

                override fun onCardError(exception: Exception) {
                    sendToFlutter("onCardError", exception.message)
                }
            })
        } catch (e: Exception) {
            sendToFlutter("onNFCError", "NFC processing error: ${e.message}")
        }
    }

private fun convertBitmapToBase64(bitmap: Bitmap): String {
    val byteArrayOutputStream = ByteArrayOutputStream()
    // Use JPEG instead of PNG for better compatibility
    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, byteArrayOutputStream)
    val byteArray = byteArrayOutputStream.toByteArray()
    val base64 = android.util.Base64.encodeToString(byteArray, android.util.Base64.NO_WRAP)
    return base64
}
    private fun sendToFlutter(method: String, arguments: Any?) {
        runOnUiThread {
            flutterEngine?.let { engine ->
                try {
                    MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod(method, arguments)
                } catch (e: Exception) {
                    println("Error sending to Flutter: ${e.message}")
                }
            }
        }
    }


private fun handleDetectMRZFromBitmap(call: MethodCall, result:MethodChannel.Result) {
    try {
        val bitmapBytes = call.argument<ByteArray>("bitmapBytes")
        
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

private fun handleDetectTextFromBitmap(call: MethodCall, result: MethodChannel.Result) {
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

private fun handleDetectTextFromFrame(call: MethodCall, result: MethodChannel.Result) {
    try {
        val frameData = call.argument<ByteArray>("frameData")
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0
        val rotation = call.argument<Int>("rotation") ?: 0
        
        
        if (frameData == null || width == 0 || height == 0) {
            result.error("FRAME_ERROR", "Invalid frame data", null)
            return
        }
        
        val frame = Frame(
            size = Resolution(width, height),
            image = frameData,
            rotation = rotation
        )
        
        
        sdk?.detectTextFromFrame(frame, rotation, object : AlgerianIDPassportSDK.MRZDetectionCallback {
            override fun onMRZDetected(mrzInfo: MRZInfo) {
                val mrzMap = convertMRZInfoToMap(mrzInfo)
                result.success(mapOf("success" to true, "mrzInfo" to mrzMap, "text" to "MRZ detected"))
            }

            override fun onMRZDetectionFailed(error: String) {
    result.success(mapOf(
        "success" to false, 
        "error" to error, 
        "text" to "OCR_TEXT_HERE"  
    ))
            }

            override fun onMRZDetectionError(exception: Exception) {
                result.error("FRAME_OCR_ERROR", exception.message, null)
            }
        })
        
    } catch (e: Exception) {
        result.error("FRAME_PROCESSING_ERROR", e.message, null)
    }
}
private fun handleDetectTextFromByteData(call: MethodCall, result: MethodChannel.Result) {
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

// ===== TOKEN HANDLERS IN MAIN ACTIVITY =====
    private fun handleInitializeWithToken(call: MethodCall, result: MethodChannel.Result) {
        val token = call.argument<String>("userToken") ?: ""
        
        if (token.isEmpty()) {
            result.error("INIT_ERROR", "Token cannot be empty", null)
            return
        }
        
        runBlocking {
            try {
                sdk = AlgerianIDPassportSDK(applicationContext)
                sdk?.initialize(token)
                result.success(true)
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.message, null)
            }
        }
    }
    
    private fun handleGetTokenStatus(result: MethodChannel.Result) {
        runBlocking {
            try {
                val status = sdk?.getTokenStatus()
                val statusMap = mapOf(
                    "hasValidToken" to (status?.hasValidToken ?: false),
                    "message" to (status?.message ?: "Unknown"),
                    "email" to (status?.email ?: ""),
                    "name" to (status?.name ?: "")
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
}