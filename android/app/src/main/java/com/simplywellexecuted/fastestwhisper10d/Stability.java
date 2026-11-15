// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
package com.simplywellexecuted.fastestwhisper10d;

/**
 * Stability-9L3PX5-U16LE-v1: three interlocked five-input Pentagonal XOR
 * rings over nine acoustic ligands. Pure Java 17, no weights or dependencies.
 * The scalar is ring agreement, NOT authentication or acoustic quality.
 */
public final class Stability {
    private Stability() {}

    public static final String PROTOCOL = "Stability-9L3PX5-U16LE-v1";
    public static final String[] NAMES = {
        "frame_count", "mean_left", "mean_right", "rms_left",
        "rms_right", "peak_left", "peak_right",
        "zero_crossings_left", "zero_crossings_right"
    };

    public static final int[][] RINGS = {
        {0, 1, 2, 3, 4},
        {3, 4, 5, 6, 7},
        {6, 7, 8, 0, 1}
    };

    public static final class Result {
        public final double[] ligands;
        public final double[] probabilities;
        public final int[] words;
        public final byte[] hexabyteBytes;
        public final String hexabyte;
        public final double scalar;

        private Result(double[] ligands, double[] probabilities, int[] words,
                       byte[] hexabyteBytes, String hexabyte, double scalar) {
            this.ligands = ligands.clone();
            this.probabilities = probabilities.clone();
            this.words = words.clone();
            this.hexabyteBytes = hexabyteBytes.clone();
            this.hexabyte = hexabyte;
            this.scalar = scalar;
        }
    }

    private static void finite(double value) {
        if (!Double.isFinite(value)) {
            throw new IllegalArgumentException("Measurements must be finite.");
        }
    }

    public static double[] normalize(double[] measurements) {
        if (measurements == null || measurements.length != 9) {
            throw new IllegalArgumentException("Exactly nine measurements required.");
        }
        for (double v : measurements) finite(v);

        final double n = measurements[0];
        if (n < 1 || Math.floor(n) != n) {
            throw new IllegalArgumentException("Frame count must be positive integer.");
        }

        double[] h = new double[9];
        h[0] = n / (n + 1024.0);
        for (int i = 1; i <= 2; i++) {
            double m = measurements[i];
            h[i] = 0.5 * (1.0 + m / (1.0 + Math.abs(m)));
        }
        for (int i = 3; i <= 6; i++) {
            if (measurements[i] < 0.0) {
                throw new IllegalArgumentException("RMS/peak cannot be negative.");
            }
            h[i] = measurements[i] / (1.0 + measurements[i]);
        }
        final double maximumCrossings = n - 1.0;
        for (int i = 7; i <= 8; i++) {
            double crosses = measurements[i];
            if (crosses < 0 || Math.floor(crosses) != crosses ||
                crosses > maximumCrossings) {
                throw new IllegalArgumentException("Invalid zero-crossing count.");
            }
            h[i] = crosses / Math.max(1.0, maximumCrossings);
        }
        for (double v : h) {
            if (!Double.isFinite(v) || v < 0.0 || v > 1.0) {
                throw new IllegalArgumentException("Invalid normalized ligand.");
            }
        }
        return h;
    }

    public static Result calculate(double[] ligands) {
        if (ligands == null || ligands.length != 9) {
            throw new IllegalArgumentException("Exactly nine ligands required.");
        }
        for (double h : ligands) {
            if (!Double.isFinite(h) || h < 0.0 || h > 1.0) {
                throw new IllegalArgumentException("Ligands must be in [0,1].");
            }
        }
        double[] p = new double[3];
        int[] words = new int[3];
        byte[] six = new byte[6];
        for (int ring = 0; ring < 3; ring++) {
            double product = 1.0;
            for (int index : RINGS[ring]) {
                product *= (1.0 - 2.0 * ligands[index]);
            }
            p[ring] = Math.max(0.0, Math.min(1.0, 0.5 * (1.0 - product)));
            words[ring] = (int) Math.floor(p[ring] * 65535.0 + 0.5);
            six[ring * 2] = (byte) (words[ring] & 0xff);
            six[ring * 2 + 1] = (byte) ((words[ring] >>> 8) & 0xff);
        }

        double low = Math.min(p[0], Math.min(p[1], p[2]));
        double high = Math.max(p[0], Math.max(p[1], p[2]));
        double scalar = Math.max(0.0, Math.min(1.0, 1.0 - (high - low)));

        final char[] digits = "0123456789abcdef".toCharArray();
        StringBuilder hex = new StringBuilder(12);
        for (byte value : six) {
            int unsigned = value & 0xff;
            hex.append(digits[unsigned >>> 4]).append(digits[unsigned & 15]);
        }
        return new Result(ligands, p, words, six, hex.toString(), scalar);
    }
}
