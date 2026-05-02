package itsicherheit;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;

public final class Decrypt {
    private Decrypt() {
    }

    public static void main(String[] args) {
        try {
            System.out.println(decryptFromStdin(args));
        } catch (IllegalArgumentException | IOException ex) {
            System.err.println(ex.getMessage());
            System.exit(1);
        }
    }

    static String decryptFromStdin(String[] args) throws IOException {
        if (args.length != 3) {
            throw new IllegalArgumentException("Usage: decrypt <m> <g> <priv>");
        }

        BigInteger modulus = HexUtil.fromHex(args[0]);
        HexUtil.fromHex(args[1]);
        BigInteger privateKey = HexUtil.fromHex(args[2]);

        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
        String firstLine = reader.readLine();
        if (firstLine == null || !firstLine.startsWith("MyPubkey:")) {
            throw new IllegalArgumentException("Fehler: Erste Zeile muss 'MyPubkey: <hex>' enthalten.");
        }

        StringBuilder ciphertext = new StringBuilder();
        String line;
        boolean firstCipherLine = true;
        boolean separatorChecked = false;
        while ((line = reader.readLine()) != null) {
            if (!separatorChecked) {
                separatorChecked = true;
                if (line.isEmpty()) {
                    continue;
                }
            }
            if (!firstCipherLine) {
                ciphertext.append('\n');
            }
            ciphertext.append(line);
            firstCipherLine = false;
        }

        BigInteger senderPublicKey = HexUtil.fromHex(firstLine.split(":", 2)[1].trim());
        BigInteger sharedSecret = DiffieHellman.sharedSecret(modulus, senderPublicKey, privateKey);
        String key = Vigenere.secretToKey(sharedSecret);
        return Vigenere.decrypt(ciphertext.toString(), key);
    }
}
