package itsicherheit;

import java.math.BigInteger;

final class Vigenere {
    private static final BigInteger BASE_26 = BigInteger.valueOf(26);

    private Vigenere() {
    }

    static String secretToKey(BigInteger secret) {
        if (BigInteger.ZERO.equals(secret)) {
            return "A";
        }

        StringBuilder reversed = new StringBuilder();
        BigInteger value = secret;
        while (value.signum() > 0) {
            BigInteger[] divRem = value.divideAndRemainder(BASE_26);
            reversed.append((char) ('A' + divRem[1].intValue()));
            value = divRem[0];
        }

        return reversed.reverse().toString();
    }

    static String decrypt(String ciphertext, String key) {
        StringBuilder result = new StringBuilder(ciphertext.length());
        int keyIndex = 0;

        for (int i = 0; i < ciphertext.length(); i++) {
            char c = ciphertext.charAt(i);
            if (c == '+') {
                result.append('!');
            } else if (c >= 'A' && c <= 'Z') {
                int shift = key.charAt(keyIndex % key.length()) - 'A';
                result.append((char) ('A' + Math.floorMod(c - 'A' - shift, 26)));
                keyIndex++;
            } else if (c >= 'a' && c <= 'z') {
                int shift = key.charAt(keyIndex % key.length()) - 'A';
                result.append((char) ('a' + Math.floorMod(c - 'a' - shift, 26)));
                keyIndex++;
            } else {
                result.append(c);
            }
        }

        return result.toString();
    }
}
