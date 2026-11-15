// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
package com.simplywellexecuted.fastestwhisper10d;

import java.io.BufferedInputStream;
import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Streaming acoustic analysis of raw interleaved stereo float32-le frames.
 * Source bytes are read-only; no model, network, or transcript engine is used.
 */
public final class Acoustic10D {
    private Acoustic10D() {}

    public static final class Analysis {
        public final long frames;
        public final double[] vector;
        public final Stability.Result stability;
        public final double legacyPearson;
        public final String inputSha256;

        private Analysis(long frames, double[] vector, Stability.Result stability,
                         double legacyPearson, String inputSha256) {
            this.frames = frames;
            this.vector = vector.clone();
            this.stability = stability;
            this.legacyPearson = legacyPearson;
            this.inputSha256 = inputSha256;
        }
    }

    public static Analysis inspect(InputStream input) throws IOException {
        if (input == null) throw new IllegalArgumentException("Missing input stream.");
        MessageDigest digest;
        try {
            digest = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 runtime unavailable.", ex);
        }
        BufferedInputStream stream = new BufferedInputStream(input);
        byte[] buffer = new byte[8];
        ByteBuffer frame = ByteBuffer.wrap(buffer).order(ByteOrder.LITTLE_ENDIAN);

        long count = 0;
        long leftCrossings = 0, rightCrossings = 0;
        double meanL = 0.0, meanR = 0.0;
        double m2L = 0.0, m2R = 0.0, covariance = 0.0;
        double powerL = 0.0, powerR = 0.0;
        double peakL = 0.0, peakR = 0.0;
        double previousL = 0.0, previousR = 0.0;

        while (true) {
            int first = stream.read();
            if (first < 0) break;
            buffer[0] = (byte) first;
            int offset = 1;
            while (offset < 8) {
                int read = stream.read(buffer, offset, 8 - offset);
                if (read < 0) throw new EOFException("Truncated stereo float32 frame.");
                if (read == 0) continue;
                offset += read;
            }
            digest.update(buffer);

            frame.position(0);
            double l = frame.getFloat();
            double r = frame.getFloat();
            if (!Double.isFinite(l) || !Double.isFinite(r)) {
                throw new IOException("Nonfinite audio sample.");
            }
            if (count > 0) {
                if (previousL != 0.0 && l != 0.0 &&
                    (previousL < 0.0) != (l < 0.0)) leftCrossings++;
                if (previousR != 0.0 && r != 0.0 &&
                    (previousR < 0.0) != (r < 0.0)) rightCrossings++;
            }
            if (count == Long.MAX_VALUE) throw new IOException("Frame count overflow.");
            count++;
            double deltaL = l - meanL;
            double deltaR = r - meanR;
            meanL += deltaL / count;
            meanR += deltaR / count;
            m2L += deltaL * (l - meanL);
            m2R += deltaR * (r - meanR);
            covariance += deltaL * (r - meanR);
            powerL += l * l;
            powerR += r * r;
            peakL = Math.max(peakL, Math.abs(l));
            peakR = Math.max(peakR, Math.abs(r));
            previousL = l;
            previousR = r;
        }

        if (count == 0) throw new IOException("Empty input has no acoustic features.");
        double pearson = 0.0;
        if (m2L > 0.0 && m2R > 0.0) {
            pearson = Math.max(-1.0, Math.min(1.0,
                covariance / Math.sqrt(m2L * m2R)));
        }

        double[] measurements = {
            (double) count, meanL, meanR,
            Math.sqrt(powerL / count), Math.sqrt(powerR / count),
            peakL, peakR, (double) leftCrossings, (double) rightCrossings
        };
        for (double value : measurements) {
            if (!Double.isFinite(value)) {
                throw new IOException("Numeric overflow in acoustic measurements.");
            }
        }
        Stability.Result stability = Stability.calculate(
            Stability.normalize(measurements));
        double[] vector = new double[10];
        System.arraycopy(measurements, 0, vector, 0, 9);
        vector[9] = stability.scalar;

        char[] hexDigits = "0123456789abcdef".toCharArray();
        StringBuilder hash = new StringBuilder(64);
        for (byte value : digest.digest()) {
            int unsigned = value & 0xff;
            hash.append(hexDigits[unsigned >>> 4]);
            hash.append(hexDigits[unsigned & 15]);
        }
        return new Analysis(count, vector, stability, pearson, hash.toString());
    }
}
