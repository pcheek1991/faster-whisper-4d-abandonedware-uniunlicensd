// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
package com.simplywellexecuted.fastestwhisper10d;

import org.junit.Test;
import static org.junit.Assert.*;

public final class StabilityTest {
    private static double[] nine(double value) {
        double[] h = new double[9];
        for (int i = 0; i < h.length; i++) h[i] = value;
        return h;
    }

    @Test public void exactHexabyteGoldens() {
        Stability.Result zero = Stability.calculate(nine(0.0));
        assertEquals("000000000000", zero.hexabyte);
        assertEquals(1.0, zero.scalar, 0.0);
        assertEquals("ffffffffffff", Stability.calculate(nine(1.0)).hexabyte);
        assertEquals("008000800080", Stability.calculate(nine(0.5)).hexabyte);
        double[] overlap = nine(0.0);
        overlap[3] = 1.0;
        Stability.Result r = Stability.calculate(overlap);
        assertEquals("ffffffff0000", r.hexabyte);
        assertEquals(0.0, r.scalar, 0.0);
    }

    @Test public void independentMintermsAgree() {
        double[] h = {0.10,0.23,0.31,0.47,0.56,0.69,0.72,0.83,0.95};
        double[] before = h.clone();
        Stability.Result result = Stability.calculate(h);
        assertArrayEquals(before, h, 0.0);

        for (int j = 0; j < 3; j++) {
            double expected = 0.0;
            for (int mask = 0; mask < 32; mask++) {
                if ((Integer.bitCount(mask) & 1) == 0) continue;
                double term = 1.0;
                for (int bit = 0; bit < 5; bit++) {
                    double v = h[Stability.RINGS[j][bit]];
                    term *= (mask & (1 << bit)) != 0 ? v : 1.0-v;
                }
                expected += term;
            }
            assertEquals(expected, result.probabilities[j], 1e-12);
            int word = (int) Math.floor(expected * 65535.0 + 0.5);
            assertEquals(word, result.words[j]);
            assertEquals(word & 255, result.hexabyteBytes[2*j] & 255);
            assertEquals((word >>> 8) & 255, result.hexabyteBytes[2*j+1] & 255);
        }
    }

    @Test public void normalizeNineMeasurements() {
        double[] source = {3.0,2.0,20.0,Math.sqrt(14.0/3.0),
                           Math.sqrt(1400.0/3.0),3.0,30.0,0.0,0.0};
        double[] actual = Stability.normalize(source);
        assertEquals(9, actual.length);
        assertEquals(3.0/1027.0, actual[0], 1e-12);
        assertEquals(0.5 * (1.0 + 2.0/3.0), actual[1], 1e-12);
        assertEquals(0.0, actual[7], 0.0);
    }

    @Test public void invalidLigandsFail() {
        assertThrows(IllegalArgumentException.class,
            () -> Stability.calculate(new double[8]));
        double[] nan = nine(0.0);
        nan[7] = Double.NaN;
        assertThrows(IllegalArgumentException.class,
            () -> Stability.calculate(nan));
        double[] over = nine(0.0);
        over[2] = 1.1;
        assertThrows(IllegalArgumentException.class,
            () -> Stability.calculate(over));
    }
}
