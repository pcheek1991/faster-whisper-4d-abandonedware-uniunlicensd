// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
package com.simplywellexecuted.fastestwhisper10d;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.Test;
import static org.junit.Assert.*;

public final class Acoustic10DTest {
    private static byte[] frames(float... values) {
        ByteBuffer bytes = ByteBuffer.allocate(values.length * 4)
            .order(ByteOrder.LITTLE_ENDIAN);
        for (float value : values) bytes.putFloat(value);
        return bytes.array();
    }

    @Test public void finiteStereoFixture() throws Exception {
        byte[] input = frames(1,10,2,20,3,30);
        Acoustic10D.Analysis data = Acoustic10D.inspect(
            new ByteArrayInputStream(input));
        assertEquals(3, data.frames);
        assertEquals(10, data.vector.length);
        assertEquals(2.0, data.vector[1], 0.0);
        assertEquals(20.0, data.vector[2], 0.0);
        assertEquals(1.0, data.legacyPearson, 1e-12);
        assertEquals(data.stability.scalar, data.vector[9], 0.0);
        assertEquals(12, data.stability.hexabyte.length());
        assertEquals(64, data.inputSha256.length());
    }

    @Test public void malformedInputsFailWithoutResult() {
        assertThrows(IOException.class, () -> Acoustic10D.inspect(
            new ByteArrayInputStream(new byte[0])));
        assertThrows(IOException.class, () -> Acoustic10D.inspect(
            new ByteArrayInputStream(new byte[7])));
        assertThrows(IOException.class, () -> Acoustic10D.inspect(
            new ByteArrayInputStream(frames(Float.NaN, 0.0f))));
    }
}
