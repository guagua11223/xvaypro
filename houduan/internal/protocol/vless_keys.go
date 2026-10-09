package protocol

// Keys produced by `xray x25519`.
// The client uses Password (the X25519 public key) as VLESS encryption.
// The server uses PrivateKey as VLESS decryption. Hash32 is blake3(public key).
const (
	VLESSPrivateKey = "QNST9XVXPWDoKPhh34mPb1idEiZLqv8_yarbSHdJpXo"
	VLESSPublicKey  = "lS7SXPzEfNbk7D8gZJ2AYh8yttg1uGuFHGdaCGaS8Hs"
	VLESSHash32     = "E_vsOyNbVFGxI7nX_21-dzuyeOJa-b9zdQuDtL4o70k"
)

func VLESSKeys() map[string]any {
	return map[string]any{
		"privateKey": VLESSPrivateKey,
		"publicKey":  VLESSPublicKey,
		"password":   VLESSPublicKey,
		"hash32":     VLESSHash32,
	}
}
