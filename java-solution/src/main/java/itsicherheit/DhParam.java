package itsicherheit;

import java.math.BigInteger;

public final class DhParam {
    private static final BigInteger TWO = BigInteger.valueOf(2);

    private DhParam() {
    }

    public static void main(String[] args) {
        try {
            Params params = createParams(args);
            printParams(params);
        } catch (IllegalArgumentException ex) {
            System.err.println(ex.getMessage());
            System.exit(1);
        }
    }

    static Params createParams(String[] args) {
        BigInteger modulus;
        BigInteger generator;

        if (args.length == 0) {
            modulus = DiffieHellman.randomInRange(BigInteger.valueOf(1L << 9), BigInteger.valueOf((1L << 10) - 1));
            generator = DiffieHellman.randomInRange(TWO, modulus.subtract(BigInteger.ONE));
        } else if (args.length == 2) {
            modulus = HexUtil.fromHex(args[0]);
            generator = HexUtil.fromHex(args[1]);
            if (generator.compareTo(TWO) < 0 || generator.compareTo(modulus) >= 0) {
                throw new IllegalArgumentException("Fehler: Generator g muss im Bereich [2, m-1] liegen.");
            }
        } else {
            throw new IllegalArgumentException("Usage: dhparam [<m> <g>]");
        }

        BigInteger privateKey = DiffieHellman.generatePrivateKey(modulus);
        BigInteger publicKey = DiffieHellman.publicKey(modulus, generator, privateKey);
        return new Params(modulus, generator, privateKey, publicKey);
    }

    static void printParams(Params params) {
        System.out.println("m: " + HexUtil.toHex(params.modulus()));
        System.out.println("g: " + HexUtil.toHex(params.generator()));
        System.out.println("priv: " + HexUtil.toHex(params.privateKey()));
        System.out.println("pub: " + HexUtil.toHex(params.publicKey()));
    }

    static final class Params {
        private final BigInteger modulus;
        private final BigInteger generator;
        private final BigInteger privateKey;
        private final BigInteger publicKey;

        Params(BigInteger modulus, BigInteger generator, BigInteger privateKey, BigInteger publicKey) {
            this.modulus = modulus;
            this.generator = generator;
            this.privateKey = privateKey;
            this.publicKey = publicKey;
        }

        BigInteger modulus() {
            return modulus;
        }

        BigInteger generator() {
            return generator;
        }

        BigInteger privateKey() {
            return privateKey;
        }

        BigInteger publicKey() {
            return publicKey;
        }
    }
}
