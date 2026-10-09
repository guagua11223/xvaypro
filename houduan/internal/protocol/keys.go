package protocol

import (
	"crypto/ecdh"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"fmt"
)

// RealityKeys are the raw X25519 key pair Xray-core expects, encoded as base64url.
type RealityKeys struct {
	PrivateKey string
	PublicKey  string
}

func GenerateRealityKeys() (RealityKeys, error) {
	key, err := ecdh.X25519().GenerateKey(rand.Reader)
	if err != nil {
		return RealityKeys{}, err
	}
	return RealityKeys{
		PrivateKey: base64.RawURLEncoding.EncodeToString(key.Bytes()),
		PublicKey:  base64.RawURLEncoding.EncodeToString(key.PublicKey().Bytes()),
	}, nil
}

func PublicKeyFromPrivate(privateKey string) (string, error) {
	raw, err := base64.RawURLEncoding.DecodeString(privateKey)
	if err != nil || len(raw) != 32 {
		return "", fmt.Errorf("reality private key must be 32 bytes")
	}
	key, err := ecdh.X25519().NewPrivateKey(raw)
	if err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(key.PublicKey().Bytes()), nil
}

func GenerateShortID() (string, error) {
	buf := make([]byte, 4)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return hex.EncodeToString(buf), nil
}
