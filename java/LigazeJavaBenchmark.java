// SPDX-License-Identifier: 0BSD
// Exact input stream and six-block COR comparison as native benchmark.
// Java 17 reference, no build tools or non-JDK runtime dependencies.
import java.util.Arrays;
import java.util.Locale;
public final class LigazeJavaBenchmark {
    private LigazeJavaBenchmark() {}
    private static final int SEED=0x0badf00d;
    private static final int EXPECTED=0x15;
    private static final int REQUIRED=0x1f;
    private static void require(boolean value,String why) {
        if(!value) throw new IllegalStateException("LIGAZE_BENCH_ERROR: "+why);
    }
    private static int blocks(int raw,int expected,int conf,int required) {
        raw&=31;expected&=31;conf&=31;required&=31;
        return raw|(expected<<5)|(conf<<10)|(required<<15)|(raw<<20)|(expected<<25);
    }
    private static PentagonalControl.Vista hold(int raw,int expected,int conf,int required) {
        int observed=blocks(raw,expected,conf,required);
        int reference=blocks(expected,expected,required,required);
        return PentagonalControl.cor(observed,reference,PentagonalControl.Entry.OR,true,true,true);
    }
    private static void securityChecks() {
        PentagonalControl.Vista intact=hold(0x15,0x15,0x1f,0x1f);
        PentagonalControl.Vista flipped=hold(0x14,0x15,0x1f,0x1f);
        PentagonalControl.Vista forgedBoth=hold(0x14,0x14,0x1f,0x1f);
        PentagonalControl.Vista changedConf=hold(0x15,0x15,0x1e,0x1f);
        PentagonalControl.Vista replay=hold(0x15,0x15,0x1f,0x1f);
        PentagonalControl.Vista missing=PentagonalControl.cor(31,31,PentagonalControl.Entry.OR,false,true,true);
        PentagonalControl.Vista rollback=PentagonalControl.cor(31,31,PentagonalControl.Entry.OR,true,true,false);
        PentagonalControl.Vista stale=PentagonalControl.cor(31,31,PentagonalControl.Entry.OR,true,false,true);
        require(intact.rupture()==0 && flipped.rupture()==17 &&
            forgedBoth.rupture()==0 && changedConf.rupture()==4 &&
            replay.operand()==intact.operand() &&
            (missing.rupture()&PentagonalControl.MISSING_WITNESS)!=0 &&
            (rollback.rupture()&PentagonalControl.CLOCK_REGRESSION)!=0 &&
            (stale.rupture()&PentagonalControl.REPLAY_SEQUENCE)!=0,
            "threat model fixtures");
    }
    private static long measured(int iterations) {
        int state=SEED;
        long checksum=0;
        for(int i=0;i<iterations;i++){
            state=state*1664525+1013904223;
            int raw=(state>>>8)&31, conf=(state>>>16)&31;
            PentagonalControl.Vista witness=hold(raw,EXPECTED,conf,REQUIRED);
            int expected=(raw==EXPECTED?0:17)|(conf==REQUIRED?0:4);
            require(witness.rupture()==expected &&
                witness.evaluations()==96 &&
                witness.observed()==blocks(raw,EXPECTED,conf,REQUIRED),
                "COR workload inconsistent");
            checksum += expected*131L+raw+conf;
        }
        return checksum;
    }
    private static int positive(String arg,int max) {
        int x=Integer.parseInt(arg);
        if(x<1||x>max) throw new IllegalArgumentException("sample count outside allowed range");
        return x;
    }
    public static void main(String[] args) {
        try {
            if(args.length!=3)
                throw new IllegalArgumentException("Usage: LigazeJavaBenchmark iterations warmup repeats");
            int n=positive(args[0],10000000),warmup=positive(args[1],10000000),
                repeats=positive(args[2],11);
            securityChecks();
            require(measured(warmup)>0,"warmup not executed");
            double[] times=new double[repeats];
            long checksum=0;
            for(int r=0;r<repeats;r++){
                long t0=System.nanoTime();
                long current=measured(n);
                long t1=System.nanoTime();
                if(r>0) require(checksum==current,"checksum not deterministic");
                else checksum=current;
                times[r]=(double)(t1-t0)/n;
            }
            double[] ordered=times.clone();
            Arrays.sort(ordered);
            double median=ordered[ordered.length/2];
            require(Double.isFinite(median) && median>0,"invalid measurement");
            StringBuilder sb=new StringBuilder();
            for(int i=0;i<times.length;i++){
                if(i!=0)sb.append(',');
                sb.append(String.format(Locale.ROOT,"%.4f",times[i]));
            }
            System.out.printf(Locale.ROOT,
                "{\"schema\":\"SWE-LIGAZE-BENCH-v1\",\"runtime\":\"java17-hotspot\","+
                "\"iterations\":%d,\"warmup\":%d,\"repeats\":%d,"+
                "\"median_ns_per_call\":%.4f,\"checksum\":%d,"+
                "\"samples_ns_per_call\":[%s],\"threat_fixtures\":\"PASS\","+
                "\"same_inputs_and_expected_fixture\":true,\"external_authentication\":false}%n",
                n,warmup,repeats,median,checksum,sb.toString());
        }catch(RuntimeException e){
            System.err.println("LIGAZE_BENCH_ERROR: "+e);
            System.exit(2);
        }
    }
}
