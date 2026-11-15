// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
package com.simplywellexecuted.fastestwhisper10d;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.InputStream;
import java.util.Locale;

/**
 * Experimental offline APK for one user-selected raw stereo float32 file.
 * No Internet permission, microphone permission, model download, or transcription.
 */
public final class MainActivity extends Activity {
    private static final int SELECT_RAW_FILE = 10;
    private TextView output;
    private Button pickFile;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);

        LinearLayout column = new LinearLayout(this);
        column.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        column.setPadding(pad, pad, pad, pad);

        TextView intro = new TextView(this);
        intro.setText("Fastest-Whisper-10D\n"
            + "Experimental offline acoustic laboratory\n\n"
            + "Select a raw stereo float32 little-endian file. "
            + "No trained model is used. Stability is ring agreement, "
            + "not verified speech recognition.");
        intro.setTextSize(16f);
        column.addView(intro);

        pickFile = new Button(this);
        pickFile.setText("Select local raw audio");
        column.addView(pickFile);
        pickFile.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
            intent.addCategory(Intent.CATEGORY_OPENABLE);
            intent.setType("*/*");
            startActivityForResult(intent, SELECT_RAW_FILE);
        });

        output = new TextView(this);
        output.setText("No file selected.");
        output.setTextIsSelectable(true);
        output.setTextSize(14f);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(output);
        column.addView(scroll, new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        setContentView(column);
    }

    @Override
    protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != SELECT_RAW_FILE || result != RESULT_OK ||
            data == null || data.getData() == null) return;

        Uri uri = data.getData();
        pickFile.setEnabled(false);
        output.setText("Analyzing locally; no data is uploaded.");

        new Thread(() -> {
            String response;
            try (InputStream in = getContentResolver().openInputStream(uri)) {
                if (in == null) throw new IllegalArgumentException("File cannot be opened.");
                Acoustic10D.Analysis analysis = Acoustic10D.inspect(in);
                response = format(analysis);
            } catch (Exception error) {
                response = "Analysis failed without producing a feature vector:\n"
                    + error.getClass().getSimpleName() + ": " + error.getMessage();
            }
            final String finalResponse = response;
            runOnUiThread(() -> {
                output.setText(finalResponse);
                pickFile.setEnabled(true);
            });
        }, "FastestWhisper10D-LocalAnalyzer").start();
    }

    private static String format(Acoustic10D.Analysis result) {
        StringBuilder text = new StringBuilder();
        text.append("Stability-9L3PX5-U16LE-v1\n")
            .append("Trained model: NO\n")
            .append("Transcript generated: NO\n")
            .append("Raw frames: ").append(result.frames).append("\n")
            .append("Input SHA-256: ").append(result.inputSha256).append("\n\n");

        for (int i = 0; i < 9; i++) {
            text.append(Stability.NAMES[i]).append(": ")
                .append(String.format(Locale.ROOT, "%.12g", result.vector[i]))
                .append("\n");
        }
        text.append("\nStability (dimension 10): ")
            .append(String.format(Locale.ROOT, "%.12g", result.vector[9]))
            .append("\nHexabyte (six bytes, LE): ")
            .append(result.stability.hexabyte)
            .append("\n");
        for (int i = 0; i < 3; i++) {
            text.append("Ring ").append(i + 1).append(": ")
                .append(String.format(Locale.ROOT, "%.12g",
                    result.stability.probabilities[i]))
                .append("  (U16 ")
                .append(result.stability.words[i]).append(")\n");
        }
        text.append("\nNine normalized ligands:\n");
        for (int i = 0; i < 9; i++) {
            text.append(i).append(": ")
                .append(String.format(Locale.ROOT, "%.12g",
                    result.stability.ligands[i]))
                .append("\n");
        }
        text.append("\nThe score measures mathematical ring agreement, "
            + "not acoustic quality or recognized words.");
        return text.toString();
    }
}
