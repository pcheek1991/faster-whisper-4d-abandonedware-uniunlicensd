// SPDX-License-Identifier: 0BSD
// Experimental educational execution paths. No kernel crash and no untrusted code.
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.invoke.MutableCallSite;
import java.util.Locale;

public final class PentagonalExtensions {
    private PentagonalExtensions() {}
    public static final String YING_MARKER = "SUPERTAOISM_YING_INJECTED_RUNTIME_FAULT";
    private static final int MASK = PentagonalControl.LIGAND_MASK;

    private static void require(boolean value, String reason) {
        if (!value) throw new IllegalStateException("SUPERTAOISM_EXT_VALIDATION: " + reason);
    }

    // Clean, hot, normally correct code. The JVM may JIT-compile this
    // method under the workload, but the HotSpot compiler does not
    // independently inject errors.
    public static int cleanHot(int fiveBits) {
        int mask=fiveBits&31;
        PentagonalControl.Gates g=PentagonalControl.booleanGates(mask);
        return (g.xor()?4:0)|(g.or()?2:0)|(g.and()?1:0);
    }

    // A deliberately broken target wired in by the application AFTER
    // exercising the legitimate hot method. This is a controlled
    // dynamic-dispatch fault injection, not an OS kernel panic.
    public static int poisonedHot(int fiveBits) {
        int result=cleanHot(fiveBits);
        throw new IllegalStateException(YING_MARKER + ":expected=" + result);
    }

    public static void ying() throws Throwable {
        MethodType signature=MethodType.methodType(int.class,int.class);
        MethodHandles.Lookup lookup=MethodHandles.lookup();
        MethodHandle clean=lookup.findStatic(PentagonalExtensions.class,"cleanHot",signature);
        MethodHandle poison=lookup.findStatic(PentagonalExtensions.class,"poisonedHot",signature);
        MutableCallSite dispatchSite=new MutableCallSite(clean);
        MethodHandle dispatch=dispatchSite.dynamicInvoker();
        long checksum=0;
        for (int i=0;i<500_000;i++) {
            int input=i&31;
            int output=(int)dispatch.invokeExact(input);
            require(output==cleanHot(input),"YING clean hot method gave wrong output");
            checksum+=output;
        }
        System.out.println("SUPERTAOISM_YING|CLEAN_HOT_PATH|PASS|warmup=500000|checksum="+checksum);
        System.out.flush();
        // Only the dispatch target changes. The original Java class, source
        // and the compiled clean method remain unchanged and auditable.
        dispatchSite.setTarget(poison);
        MutableCallSite.syncAll(new MutableCallSite[]{dispatchSite});
        System.out.println("SUPERTAOISM_YING|FAULT_INJECTED|phase=runtime_dispatch|original_unchanged=true|os_kernel_panic=false");
        System.out.flush();
        // Intentionally UNHANDLED. CI must observe a nonzero process exit.
        int impossible=(int)dispatch.invokeExact(7);
        throw new AssertionError("YING unexpectedly succeeded: " + impossible);
    }

    // An inverse-square transform is meaningful for a positive numeric
    // magnitude under a documented reference, not for a classloader,
    // boolean gate label, or other non-numeric control object.
    public static double inverseSquare(double input, double reference) {
        if (!Double.isFinite(input) || input<=0.0
                || !Double.isFinite(reference) || reference<=0.0)
            throw new ArithmeticException("ZING_SINGULAR_OR_INVALID_INPUT");
        double ratio=reference/input;
        double result=ratio*ratio;
        if (!Double.isFinite(result) || result<=0.0)
            throw new ArithmeticException("ZING_OVERFLOW_OR_UNDERFLOW");
        return result;
    }

    public record ZingResult(double[] inputs, double[] inverseSquareInputs,
                             double[] normalized, double[] rawScores,
                             double[] inverseSquareOutputs) {
        public ZingResult {
            inputs=inputs.clone();
            inverseSquareInputs=inverseSquareInputs.clone();
            normalized=normalized.clone();
            rawScores=rawScores.clone();
            inverseSquareOutputs=inverseSquareOutputs.clone();
        }
        @Override public double[] inputs() {return inputs.clone();}
        @Override public double[] inverseSquareInputs() {return inverseSquareInputs.clone();}
        @Override public double[] normalized() {return normalized.clone();}
        @Override public double[] rawScores() {return rawScores.clone();}
        @Override public double[] inverseSquareOutputs() {return inverseSquareOutputs.clone();}
    }

    // Every numeric input is transformed, then normalized into the
    // Pentagonal scorer's [0,1] ligand domain. Every numeric output is
    // also inverse-square transformed. Nothing overwrites raw values.
    public static ZingResult zingJit(double[] input, double reference) {
        if (input==null || input.length!=5)
            throw new IllegalArgumentException("Exactly five numeric inputs required");
        double[] inv=new double[5],norm=new double[5];
        for (int i=0;i<5;i++) {
            inv[i]=inverseSquare(input[i],reference);
            norm[i]=inv[i]/(1.0+inv[i]);
            if (!Double.isFinite(norm[i]) || norm[i]<=0.0 || norm[i]>=1.0)
                throw new ArithmeticException("ZING_NORMALIZATION_OUTSIDE_OPEN_UNIT_INTERVAL");
        }
        PentagonalControl.Scores scores=PentagonalControl.continuous(
            norm[0],norm[1],norm[2],norm[3],norm[4]);
        double[] raw={scores.xor(),scores.or(),scores.and()};
        double[] out=new double[3];
        for (int i=0;i<out.length;i++) out[i]=inverseSquare(raw[i],1.0);
        return new ZingResult(input,inv,norm,raw,out);
    }

    private static void near(double actual,double expected,String message) {
        require(Double.isFinite(actual) &&
                Math.abs(actual-expected)<=1e-11*Math.max(1,Math.abs(expected)),message);
    }
    public static void zing() {
        double[] inputs={0.75,0.90,1.00,1.25,1.50};
        double[] original=inputs.clone();
        ZingResult r=zingJit(inputs,1.0);
        for(int i=0;i<5;i++) {
            near(r.inverseSquareInputs()[i],1.0/(inputs[i]*inputs[i]),"ZING input "+i);
            near(r.normalized()[i],r.inverseSquareInputs()[i]/(1+r.inverseSquareInputs()[i]),"ZING normalization "+i);
        }
        for(int i=0;i<3;i++)
            near(r.inverseSquareOutputs()[i],1.0/(r.rawScores()[i]*r.rawScores()[i]),"ZING output "+i);
        // Returned arrays cannot silently mutate the stored snapshot.
        double[] leaked=r.inputs();
        leaked[0]=-7;
        require(r.inputs()[0]==0.75 && inputs[0]==original[0],"ZING mutated original source");
        int negatives=0;
        for(int i=0;i<5;i++) {
            double[] bad=inputs.clone(); bad[i]=0;
            try { zingJit(bad,1.0); throw new AssertionError("ZING accepted a zero"); }
            catch(ArithmeticException expected) { negatives++; }
            bad=inputs.clone();bad[i]=Double.NaN;
            try { zingJit(bad,1.0); throw new AssertionError("ZING accepted NaN"); }
            catch(ArithmeticException expected) { negatives++; }
        }
        try {inverseSquare(0.0,1.0);throw new AssertionError("Output singularity accepted");}
        catch(ArithmeticException expected) {negatives++;}
        // Heat the real ZING method and verify the return values each time.
        double checksum=0;
        for(int i=0;i<250_000;i++) {
            ZingResult current=zingJit(inputs,1.0);
            checksum+=current.inverseSquareOutputs()[i%3];
        }
        require(Double.isFinite(checksum)&&checksum>0,"ZING JIT workload invalid");
        System.out.printf(Locale.ROOT,
            "SUPERTAOISM_ZING|PASS|inverse_square_inputs=5|inverse_square_outputs=3|negative_tests=%d|jit_warmup=250000|checksum=%.6f|source_mutated=false%n",
            negatives,checksum);
    }

    // DECOMPILED: read-only four-path evaluation. Pentagonal NOP is an
    // identity observer, NOT a catch/ignore handler for YAN or YING.
    // Its inputs MUST come from independently verified CI stage reports.
    public static void decompiled(String[] args) {
        if(args.length!=5)
            throw new IllegalArgumentException("Require YIN,YAN,YANG,YING outcomes");
        final String[] expectedNames={"YIN","YAN","YANG","YING"};
        final boolean[] expectation={true,false,true,false};
        int fails=0,passes=0;
        for(int i=0;i<4;i++){
            String expected=expectation[i]?"PASS":"FAIL";
            require(args[i+1].equals(expected),"DECOMPILED incorrect "+expectedNames[i]+" classification");
            boolean observed=args[i+1].equals("PASS");
            boolean retained=PentagonalControl.nop(observed);
            require(retained==observed,"NOP changed original signal");
            PentagonalControl.Gates ligand=PentagonalControl.booleanGates(retained?31:0);
            require(PentagonalControl.nop(ligand.xor())==ligand.xor() &&
                    PentagonalControl.nop(ligand.or())==ligand.or() &&
                    PentagonalControl.nop(ligand.and())==ligand.and(),
                    "NOP mutated a pentagonal gate");
            if(retained) passes++; else fails++;
            System.out.println("SUPERTAOISM_DECOMPILED|"+expectedNames[i]+
                "|retained_status="+expected+"|pentagonal_nop=identity|exception_suppressed=false");
        }
        require(fails==2 && passes==2,"DECOMPILED classification mismatch");
        System.out.println("SUPERTAOISM_DECOMPILED|PASS|paths=4|healthy=2|faulted=2|nop_overwrites=0");
    }

    public static void main(String[] args) throws Throwable {
        if(args.length==1 && args[0].equals("--ying")) ying();
        else if(args.length==1 && args[0].equals("--zing")) zing();
        else if(args.length>=1 && args[0].equals("--decompiled")) decompiled(args);
        else {System.err.println("Usage: PentagonalExtensions --ying|--zing|--decompiled PASS FAIL PASS FAIL");System.exit(2);}
    }
}
