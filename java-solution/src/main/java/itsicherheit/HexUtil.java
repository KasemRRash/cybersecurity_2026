package itsicherheit;

import java.math.BigInteger;

final class HexUtil {
    private HexUtil() {
    }

    static BigInteger fromHex(String value) {
        return new BigInteger(value, 16);
    }

    static String toHex(BigInteger value) {
        return value.toString(16);
    }
}
