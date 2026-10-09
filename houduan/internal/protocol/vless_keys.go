package protocol

// Keys produced by `xray x25519`. Xray 26 rejects a bare key in decryption/encryption.
// The accepted form comes from `xray vlessenc`: mlkem768x25519plus.native.<ticket>.<key>.
const (
	VLESSPrivateKey = "QNST9XVXPWDoKPhh34mPb1idEiZLqv8_yarbSHdJpXo"
	VLESSPublicKey  = "lS7SXPzEfNbk7D8gZJ2AYh8yttg1uGuFHGdaCGaS8Hs"
	VLESSHash32     = "E_vsOyNbVFGxI7nX_21-dzuyeOJa-b9zdQuDtL4o70k"
	VLESSDecryption = "mlkem768x25519plus.native.600s." + VLESSPrivateKey
	VLESSEncryption = "mlkem768x25519plus.native.0rtt." + VLESSPublicKey
)

func VLESSKeys() map[string]any {
	return map[string]any{
		"privateKey": VLESSPrivateKey,
		"publicKey":  VLESSPublicKey,
		"password":   VLESSPublicKey,
		"hash32":     VLESSHash32,
		"decryption": VLESSDecryption,
		"encryption": VLESSEncryption,
	}
}
