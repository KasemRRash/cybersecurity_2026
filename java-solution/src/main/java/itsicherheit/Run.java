package itsicherheit;

import java.io.IOException;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public final class Run {
    private Run() {
    }

    public static void main(String[] args) {
        try {
            run(args);
        } catch (IllegalArgumentException | IOException ex) {
            System.err.println(ex.getMessage());
            System.exit(1);
        }
    }

    static void run(String[] args) throws IOException {
        if (args.length < 3 || args.length > 4) {
            throw new IllegalArgumentException("Usage: run <m> <g> <prof_pubkey> [--decrypt]");
        }

        String modulusHex = args[0];
        String generatorHex = args[1];
        String professorPublicKey = args[2];
        String mode = args.length == 4 ? args[3] : "";

        Path sessionFile = Path.of(System.getProperty("java.io.tmpdir"), "dh_session_" + modulusHex + ".tmp");
        String privateKeyHex;
        String publicKeyHex;

        if (Files.notExists(sessionFile)) {
            DhParam.Params params = DhParam.createParams(new String[] { modulusHex, generatorHex });
            privateKeyHex = HexUtil.toHex(params.privateKey());
            publicKeyHex = HexUtil.toHex(params.publicKey());
            Files.writeString(sessionFile, privateKeyHex + System.lineSeparator() + publicKeyHex + System.lineSeparator(),
                    StandardCharsets.UTF_8);

            System.err.println("=== Eigene DH-Parameter ===");
            printParamsToStderr(params);
        } else {
            String[] cached = Files.readString(sessionFile, StandardCharsets.UTF_8).split("\\R");
            privateKeyHex = cached[0];
            publicKeyHex = cached[1];
            System.err.println("(Gecachtes Schluesselpaar wird verwendet)");
        }

        System.err.println();
        System.err.println("Mein Public Key (fuer dhmsg): " + publicKeyHex);
        System.err.println();

        if ("--decrypt".equals(mode)) {
            BigInteger modulus = HexUtil.fromHex(modulusHex);
            HexUtil.fromHex(generatorHex);
            BigInteger privateKey = HexUtil.fromHex(privateKeyHex);
            String plaintext = Decrypt.decryptFromStdin(new String[] {
                    HexUtil.toHex(modulus),
                    generatorHex,
                    HexUtil.toHex(privateKey)
            });
            System.out.println(plaintext);
            Files.deleteIfExists(sessionFile);
        } else if (mode.isEmpty()) {
            System.err.println("Naechster Schritt:");
            System.err.println("  echo 'Text' | /usr/local/bin/dhmsg " + modulusHex + " " + generatorHex + " "
                    + publicKeyHex + " | java -cp out itsicherheit.Run " + modulusHex + " " + generatorHex + " "
                    + professorPublicKey + " --decrypt");
        } else {
            throw new IllegalArgumentException("Usage: run <m> <g> <prof_pubkey> [--decrypt]");
        }
    }

    private static void printParamsToStderr(DhParam.Params params) {
        System.err.println("m: " + HexUtil.toHex(params.modulus()));
        System.err.println("g: " + HexUtil.toHex(params.generator()));
        System.err.println("priv: " + HexUtil.toHex(params.privateKey()));
        System.err.println("pub: " + HexUtil.toHex(params.publicKey()));
    }
}
