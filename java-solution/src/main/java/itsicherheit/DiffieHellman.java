package itsicherheit;

import java.math.BigInteger;
import java.security.SecureRandom;

final class DiffieHellman {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final BigInteger TWO = BigInteger.valueOf(2);

    private DiffieHellman() {
    }

    static BigInteger randomInRange(BigInteger minInclusive, BigInteger maxInclusive) {
        if (minInclusive.compareTo(maxInclusive) > 0) {
            throw new IllegalArgumentException("ungueltiger Zufallsbereich");
        }

        BigInteger span = maxInclusive.subtract(minInclusive).add(BigInteger.ONE);
        BigInteger candidate;
        do {
            candidate = new BigInteger(span.bitLength(), RANDOM);
        } while (candidate.compareTo(span) >= 0);

        return minInclusive.add(candidate);
    }

    static BigInteger generatePrivateKey(BigInteger modulus) {
        return randomInRange(TWO, modulus.subtract(TWO));
    }

    static BigInteger publicKey(BigInteger modulus, BigInteger generator, BigInteger privateKey) {
        return generator.modPow(privateKey, modulus);
    }

    static BigInteger sharedSecret(BigInteger modulus, BigInteger peerPublicKey, BigInteger privateKey) {
        return peerPublicKey.modPow(privateKey, modulus);
    }
}
