// SPDX-License-Identifier: 0BSD
// SUPERTAOISM GAMP4-style illustrative runtime assurance exercise.
// No auto-repair, no hidden NOP bypass, no regulatory approval.
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.invoke.MutableCallSite;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Locale;
import javax.tools.JavaCompiler;
import javax.tools.ToolProvider;

public final class SupertaoismGamp4 {
    private SupertaoismGamp4() {}
    private static final int BASELINE = PentagonalControl.LIGAND_MASK;
    private static final String POISON_MARKER = "SUPERTAOISM_YAN_RUNTIME_POISON";
    private static final String RECOVERY_DIGEST = "dd57ce6e8bbeeaad4af14cb06a08ec83c38d2deab16e814f97e963f5a94b0114";
    // The vetted fallback is compiled at runtime only after the YAN fault is observed.
    // It performs all SIX original gate steps and checks their actual outputs.
    // Deliberate NOP-stage semantics remain; it is never used to mask the fault.
    private static final String RECOVERY_SOURCE = """
            public final class ApprovedRecovery {
                private ApprovedRecovery() {}
                public static long cycle(PentagonalControl.Machine machine, int observed) {
                    if ((observed & ~PentagonalControl.LIGAND_MASK) != 0) {
                        throw new IllegalArgumentException("Observed data outside ligand register");
                    }
                    PentagonalControl.Gates gate = PentagonalControl.booleanGates(observed & 31);
                    int mismatch = 0;
                    for (int block=0; block<6; block++) {
                        if (((observed >>> (5*block)) & 31) != 31) mismatch |= 1 << block;
                    }
                    long before = machine.completed();
                    PentagonalControl.Stage[] stages = PentagonalControl.Stage.values();
                    for (int position=0; position<stages.length; position++) {
                        PentagonalControl.Step step = machine.tick(
                            observed, PentagonalControl.LIGAND_MASK,
                            PentagonalControl.Entry.OR, true, true, true);
                        if (step.stage() != stages[position]) {
                            throw new IllegalStateException("Recovered stage order invalid");
                        }
                        if (position==0 && step.value()!=gate.xor())
                            throw new IllegalStateException("Recovered XOR is incorrect");
                        if (position==1 && step.value()!=gate.or())
                            throw new IllegalStateException("Recovered OR is incorrect");
                        if (position==2 && step.value()!=gate.and())
                            throw new IllegalStateException("Recovered AND is incorrect");
                        if (position==3 && step.value()!=gate.and())
                            throw new IllegalStateException("NOP did not preserve the AND output");
                        if (position==4 && (step.vista()==null ||
                            step.vista().rupture()!=mismatch ||
                            step.vista().evaluations()!=96 ||
                            step.vista().observed()!=observed)) {
                            throw new IllegalStateException("Recovered COR/VISTA did not validate");
                        }
                    }
                    if (machine.completed()!=before+1 ||
                        machine.next()!=PentagonalControl.Stage.XOR) {
                        throw new IllegalStateException("FLOP did not close exactly six steps");
                    }
                    return ((long)mismatch << 3) |
                        (gate.xor()?4:0) | (gate.or()?2:0) | (gate.and()?1:0);
                }
            }
            """;

    // Compiles and links, but intentionally fails only WHEN INVOKED.
    public static final class PoisonedCycle {
        private PoisonedCycle() {}
        public static long cycle(PentagonalControl.Machine machine, int observed) {
            throw new IllegalStateException(POISON_MARKER);
        }
    }

    private static void check(boolean condition, String label) {
        if (!condition) throw new IllegalStateException("SUPERTAOISM_VALIDATION_FAILED: " + label);
    }
    private static String sha256(byte[] bytes) throws Exception {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder builder = new StringBuilder(64);
        for (byte b : digest) builder.append(String.format(Locale.ROOT,"%02x",b & 255));
        return builder.toString();
    }
    private static String checkedRecoveryDigest() throws Exception {
        String actual=sha256(RECOVERY_SOURCE.getBytes(StandardCharsets.UTF_8));
        check(actual.equals(RECOVERY_DIGEST),"Recovery source changed without explicit approval");
        return actual;
    }
    private static MethodType signature() {
        return MethodType.methodType(long.class,PentagonalControl.Machine.class,int.class);
    }
    private static MutableCallSite poisonedLink() throws Exception {
        MutableCallSite site=new MutableCallSite(signature());
        site.setTarget(MethodHandles.lookup().findStatic(PoisonedCycle.class,"cycle",signature()));
        return site;
    }
    private static void detectPoison(MethodHandle target) throws Throwable {
        try {
            long ignored=(long)target.invokeExact(new PentagonalControl.Machine(),BASELINE);
            throw new AssertionError("YAN unexpectedly ran without throwing: " + ignored);
        } catch (IllegalStateException expected) {
            check(POISON_MARKER.equals(expected.getMessage()),"Unknown runtime error, not approved YAN poison");
        }
    }
    private static final class Recovery implements AutoCloseable {
        final Path root;
        final URLClassLoader loader;
        final MethodHandle target;
        Recovery(Path root,URLClassLoader loader,MethodHandle target) {
            this.root=root;this.loader=loader;this.target=target;
        }
        @Override public void close() throws IOException {
            loader.close();
            // Delete ONLY our temporary files, never canonical datum or source.
            Files.deleteIfExists(root.resolve("ApprovedRecovery.class"));
            Files.deleteIfExists(root.resolve("ApprovedRecovery.java"));
            Files.deleteIfExists(root);
        }
    }
    private static Recovery compileApprovedRecovery() throws Throwable {
        checkedRecoveryDigest();
        JavaCompiler compiler=ToolProvider.getSystemJavaCompiler();
        check(compiler!=null,"A complete JDK 17 is required for just-in-time source compilation");
        Path temp=Files.createTempDirectory("supertaoism-approved-");
        Path source=temp.resolve("ApprovedRecovery.java");
        Files.writeString(source,RECOVERY_SOURCE,StandardCharsets.UTF_8);
        check(sha256(Files.readAllBytes(source)).equals(RECOVERY_DIGEST),"Temporary recovery source hash mismatch");
        ByteArrayOutputStream compilerLog=new ByteArrayOutputStream();
        int status;
        try(PrintStream log=new PrintStream(compilerLog,true,StandardCharsets.UTF_8)) {
            status=compiler.run(null,log,log,"--release","17","-classpath",
                System.getProperty("java.class.path"),"-d",temp.toString(),source.toString());
        }
        check(status==0,"Recovery compilation failed: "+compilerLog.toString(StandardCharsets.UTF_8));
        URLClassLoader loader=new URLClassLoader(new URL[]{temp.toUri().toURL()},SupertaoismGamp4.class.getClassLoader());
        try {
            Class<?> clazz=Class.forName("ApprovedRecovery",true,loader);
            check(clazz.getClassLoader()==loader,"Recovery class did not come from isolated loader");
            MethodHandle target=MethodHandles.publicLookup().findStatic(clazz,"cycle",signature());
            return new Recovery(temp,loader,target);
        } catch(Throwable failure) { loader.close(); throw failure; }
    }
    private static long expectedValue(int observed) {
        PentagonalControl.Gates g=PentagonalControl.booleanGates(observed&31);
        int mismatch=0;
        for(int b=0;b<6;b++) if(((observed>>>(5*b))&31)!=31) mismatch|=1<<b;
        return ((long)mismatch<<3)|(g.xor()?4:0)|(g.or()?2:0)|(g.and()?1:0);
    }
    private static long call(MethodHandle target,PentagonalControl.Machine machine,int observed) throws Throwable {
        return (long)target.invokeExact(machine,observed);
    }
    private static void verifyRecovered(MethodHandle target) throws Throwable {
        int checks=0;
        for(int mask=0;mask<32;mask++) {
            int observed=(BASELINE&~31)|mask;
            PentagonalControl.Machine machine=new PentagonalControl.Machine();
            check(call(target,machine,observed)==expectedValue(observed),"Recovered 32-state truth table mismatch");
            checks++;
        }
        for(int bit=0;bit<30;bit++) {
            int observed=BASELINE^(1<<bit);
            PentagonalControl.Machine machine=new PentagonalControl.Machine();
            check(call(target,machine,observed)==expectedValue(observed),"Recovered one-bit mismatch");
            checks++;
        }
        check(call(target,new PentagonalControl.Machine(),BASELINE)==expectedValue(BASELINE),"Healthy baseline incorrect");
        check(checks==62,"Wrong preflight check count");
    }
    private static void yinTest() throws Throwable {
        for(int bits=0;bits<32;bits++) {
            PentagonalControl.Gates g=PentagonalControl.booleanGates(bits);
            int c=Integer.bitCount(bits);
            check(g.xor()==((c&1)!=0)&&g.or()==(c>0)&&g.and()==(c==5),"YIN gate reference mismatch");
        }
        checkedRecoveryDigest();
        System.out.println("SUPERTAOISM_YIN_TEST|PASS|truth_states=32|source_mutated=false");
    }
    private static void yinTilt() {
        int corrupted=BASELINE^(1<<2);
        PentagonalControl.Vista v=PentagonalControl.cor(corrupted,BASELINE,PentagonalControl.Entry.OR,true,true,true);
        check(v.rupture()==1 && v.observed()==corrupted && v.expected()==BASELINE,"YIN fault injection missing");
        System.out.println("SUPERTAOISM_YIN_TILT|PASS|expected_fault_detected=true|rupture=1|source_mutated=false");
    }
    private static void yinValidate() throws Throwable {
        yinTest();yinTilt();
        check(PentagonalControl.vista(PentagonalControl.cor(BASELINE,BASELINE,PentagonalControl.Entry.OR,true,true,true)).rupture()==0,
            "YIN clean evidence mismatch");
        System.out.println("SUPERTAOISM_YIN_VALIDATE|PASS|source_mutated=false|pq=not_performed");
    }
    private static void yinRun(int seconds) throws Throwable {
        yinValidate();
        PentagonalControl.main(new String[]{"--stress",Integer.toString(seconds)});
        System.out.println("SUPERTAOISM_YIN_RUN|PASS|validated=true|active_seconds_min="+seconds+"|source_mutated=false");
    }
    private static void yan() throws Throwable {
        System.out.println("SUPERTAOISM_YAN|INTENTIONAL_RUNTIME_FAILURE|poison_class=PoisonedCycle|no_60_second_run=true");
        System.out.flush();
        // No catch: YAN is required to exit nonzero with an uncaught runtime failure.
        PoisonedCycle.cycle(new PentagonalControl.Machine(),BASELINE);
    }
    private static void yang(boolean timed,int seconds) throws Throwable {
        // No catch of unrecognized faults, no fallback with default/zero results.
        MutableCallSite site=poisonedLink();
        MethodHandle dispatch=site.dynamicInvoker();
        detectPoison(dispatch);
        System.out.println("SUPERTAOISM_YANG|POISON_DETECTED|marker="+POISON_MARKER);
        try(Recovery recovery=compileApprovedRecovery()) {
            // Validate new implementation BEFORE redirecting all subsequent calls.
            verifyRecovered(recovery.target);
            site.setTarget(recovery.target);
            MutableCallSite.syncAll(new MutableCallSite[]{site});
            verifyRecovered(dispatch);
            System.out.println("SUPERTAOISM_YANG_PREFLIGHT|PASS|fault_observed=true|runtime_compiled=true|relinked=true|truth_states=32|bit_flips=30|recovery_sha256="+RECOVERY_DIGEST+"|poison_unchanged=true");
            if(!timed) return;
            if(seconds<1||seconds>300) throw new IllegalArgumentException("Seconds must be between 1 and 300");
            // Warm-up is excluded from the 60-second observed interval.
            PentagonalControl.Machine machine=new PentagonalControl.Machine();
            for(int i=0;i<10000;i++) {
                int observed=BASELINE^(1<<(i%30));
                check(call(dispatch,machine,observed)==expectedValue(observed),"Warm-up regression");
            }
            long before=machine.completed();
            long start=System.nanoTime();
            long iterations=0,checksum=0;
            int lastProgress=0;
            do {
                int observed=BASELINE^(1<<(int)(iterations%30));
                long actual=call(dispatch,machine,observed);
                long expectation=expectedValue(observed);
                check(actual==expectation,"JIT-dispatched active loop result differs from canonical validation");
                checksum+=actual;
                iterations++;
                long elapsed=(System.nanoTime()-start)/1000000000L;
                if(elapsed/10>lastProgress) {
                    lastProgress=(int)(elapsed/10);
                    System.out.println("SUPERTAOISM_YANG_PROGRESS|seconds="+elapsed+"|loops="+iterations);
                }
            } while(System.nanoTime()-start<seconds*1000000000L);
            double elapsed=(System.nanoTime()-start)/1000000000.0;
            long completed=machine.completed()-before;
            check(elapsed>=seconds && completed==iterations && iterations>0,"YANG run failed duration or stage count");
            System.out.printf(Locale.ROOT,"SUPERTAOISM_YANG_RUN|PASS|elapsed_seconds=%.4f|loops=%d|checksum=%d|recovery_sha256=%s|source_mutated=false|poison_unchanged=true%n",
                elapsed,completed,checksum,RECOVERY_DIGEST);
        }
    }
    private static void usage() {
        System.err.println("Usage: java -jar pentagonal-supertaoism.jar --yin-test|--yin-tilt|--yin-validate|--yin-run 60|--yan|--yang-preflight|--yang-run 60");
    }
    public static void main(String[] args) throws Throwable {
        if(args.length==1 && args[0].equals("--yin-test")) yinTest();
        else if(args.length==1 && args[0].equals("--yin-tilt")) yinTilt();
        else if(args.length==1 && args[0].equals("--yin-validate")) yinValidate();
        else if(args.length==2 && args[0].equals("--yin-run")) yinRun(Integer.parseInt(args[1]));
        else if(args.length==1 && args[0].equals("--yan")) yan();
        else if(args.length==1 && args[0].equals("--yang-preflight")) yang(false,0);
        else if(args.length==2 && args[0].equals("--yang-run")) yang(true,Integer.parseInt(args[1]));
        else { usage(); System.exit(2); }
    }
}
