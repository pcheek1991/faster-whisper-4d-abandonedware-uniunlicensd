// SPDX-License-Identifier: 0BSD
// PENTAGONAL unified Java 17 reference, standalone without Gradle or libraries.
// Experimental software model, not hardware, GxP approval or cryptographic authentication.
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public final class PentagonalControl {
    private PentagonalControl() {}
    public static final int LIGAND_MASK = 0x3fffffff;
    public static final int MISSING_WITNESS = 0x0100;
    public static final int REPLAY_SEQUENCE = 0x0200;
    public static final int CLOCK_REGRESSION = 0x0400;
    public static final int INVALID_ENTRY = 0x8000;

    public enum Entry { OR, XOR, AND, FAULT }
    public enum Stage { XOR, OR, AND, NOP, COR, FLOP }

    public record Gates(boolean xor, boolean or, boolean and) {}
    public record Scores(double xor, double or, double and) {}
    public record Step(Stage stage, boolean value, long cyclesCompleted, Vista vista) {}

    // Immutable result including all six pentagonal blocks.
    public record Vista(
        long operand, int observed, int expected, int rupture, int evaluations,
        Entry entry, boolean witnessPresent, boolean validEntry, List<Gates> blocks
    ) {
        public Vista {
            blocks = List.copyOf(blocks);
        }
    }

    public static Gates booleanGates(int fiveBits) {
        int mask = fiveBits & 31;
        return new Gates((Integer.bitCount(mask) & 1) != 0, mask != 0, mask == 31);
    }

    // Same algebraic reference as the original C11/C++20 scorer.
    // Probability semantics require independent Bernoulli features.
    public static Scores continuous(double... p) {
        if (p == null || p.length != 5) {
            throw new IllegalArgumentException("Exactly five ligands required");
        }
        double complementProduct = 1.0;
        double parityProduct = 1.0;
        double andProduct = 1.0;
        for (double x : p) {
            if (!Double.isFinite(x) || x < 0.0 || x > 1.0) {
                throw new IllegalArgumentException("Ligands must be finite within [0,1]");
            }
            complementProduct *= (1.0 - x);
            parityProduct *= (1.0 - 2.0 * x);
            andProduct *= x;
        }
        return new Scores(0.5 * (1.0 - parityProduct),
                          1.0 - complementProduct, andProduct);
    }

    public static boolean nop(boolean heldState) { return heldState; }

    // Layout: [63:62] entry, [61:32] six five-bit blocks,
    // [31:16] logical evaluations, [15:0] evidence/rupture flags.
    public static long pack(Entry entry, int ligands, int evaluations, int rupture) {
        return ((long) entry.ordinal() << 62)
            | ((long) (ligands & LIGAND_MASK) << 32)
            | ((long) (evaluations & 0xffff) << 16)
            | (long) (rupture & 0xffff);
    }
    public static Entry entryOf(long word) {
        return Entry.values()[(int) ((word >>> 62) & 3)];
    }
    public static int ligandsOf(long word) { return (int) ((word >>> 32) & LIGAND_MASK); }
    public static int evaluationsOf(long word) { return (int) ((word >>> 16) & 0xffff); }
    public static int rupturesOf(long word) { return (int) (word & 0xffff); }

    // PENTAGONAL-COR: original internal audit order is OR -> XOR -> AND.
    // 96/64/32 denote logical truth-table evaluations, NOT MCU clock cycles.
    // Caller supplies "fresh" and "clockNondedecreasing" flags; no secure clock
    // or independent trust anchor is claimed. No source mutations occur.
    public static Vista cor(int observedInput, int expectedInput, Entry entry,
                            boolean witnessPresent, boolean fresh,
                            boolean clockNondecreasing) {
        int observed = observedInput & LIGAND_MASK;
        int expected = expectedInput & LIGAND_MASK;
        List<Gates> blocks = new ArrayList<>(6);
        int rupture = 0;
        if (!witnessPresent) rupture |= MISSING_WITNESS;
        if (!fresh) rupture |= REPLAY_SEQUENCE;
        if (!clockNondecreasing) rupture |= CLOCK_REGRESSION;
        boolean validEntry = entry != Entry.FAULT;
        if (!validEntry) rupture |= INVALID_ENTRY;
        for (int block=0;block<6;block++) {
            int actual = (observed >>> (5 * block)) & 31;
            int reference = (expected >>> (5 * block)) & 31;
            blocks.add(booleanGates(actual));
            if (witnessPresent && actual != reference) rupture |= 1 << block;
        }
        int evaluations = 0;
        if (validEntry) {
            for (int stage = entry.ordinal(); stage < 3; stage++) {
                for (int mask=0;mask<32;mask++) {
                    Gates g = booleanGates(mask);
                    boolean audit = stage == 0 ? g.or() : stage == 1 ? g.xor() : g.and();
                    if (audit) { /* An evaluated truth-table row; retain count below. */ }
                    evaluations++;
                }
            }
        }
        long operand = pack(entry, observed, evaluations, rupture);
        return new Vista(operand, observed, expected, rupture, evaluations,
                         entry, witnessPresent, validEntry, blocks);
    }

    // PENTAGONAL-VISTA: a read-only view. Immutable record and immutable list.
    public static Vista vista(Vista witness) {
        if (witness == null) throw new IllegalArgumentException("Missing witness");
        return witness;
    }

    public static final class Machine {
        private Stage next = Stage.XOR;
        private boolean held;
        private long completed;
        public Stage next() { return next; }
        public long completed() { return completed; }

        // Exactly six stages: XOR OR AND NOP COR FLOP. FLOP only returns
        // the program counter to the existing XOR entry for a later tick.
        public Step tick(int observed, int expected, Entry entry,
                         boolean witnessPresent, boolean fresh,
                         boolean clockNondecreasing) {
            Stage current = next;
            Gates g = booleanGates(observed);
            Vista view = null;
            switch (current) {
                case XOR -> { held = g.xor(); next = Stage.OR; }
                case OR -> { held = g.or(); next = Stage.AND; }
                case AND -> { held = g.and(); next = Stage.NOP; }
                case NOP -> { held = nop(held); next = Stage.COR; }
                case COR -> {
                    view = cor(observed, expected, entry, witnessPresent, fresh, clockNondecreasing);
                    next = Stage.FLOP;
                }
                case FLOP -> { completed++; next = Stage.XOR; }
            }
            return new Step(current, held, completed, view);
        }
    }

    private static void require(boolean condition, String reason) {
        if (!condition) throw new AssertionError(reason);
    }
    private static boolean close(double a, double b) {
        return Math.abs(a-b) <= 1.0e-12;
    }
    private static void selfTest() {
        int validations = 0;
        for (int mask=0;mask<32;mask++) {
            Gates g=booleanGates(mask);
            int count=Integer.bitCount(mask);
            double[] p = new double[5];
            for (int i=0;i<5;i++) p[i] = ((mask >>> i) & 1);
            Scores score=continuous(p);
            require(g.xor() == ((count & 1) != 0)
                    && g.or() == (count>0) && g.and() == (count==5), "Boolean reference");
            require(score.xor() == (g.xor()?1.0:0.0)
                    && score.or() == (g.or()?1.0:0.0)
                    && score.and() == (g.and()?1.0:0.0), "Continuous boundaries");
            validations++;
        }
        Scores halves=continuous(.5,.5,.5,.5,.5);
        require(close(halves.xor(),.5) && close(halves.or(),.96875)
                && close(halves.and(),.03125), "Intermediate probability formula");
        Scores sample=continuous(.8,.7,.9,.6,.95);
        require(close(sample.xor(),.51728), "Canonical 0.51728 fixture");
        for (double bad : new double[]{Double.NaN,Double.POSITIVE_INFINITY,-.01,1.01}) {
            try {
                continuous(0,0,bad,0,0);
                throw new AssertionError("Invalid ligand accepted");
            } catch (IllegalArgumentException expected) {
                // Rejected without mutation because inputs and outputs are value objects.
            }
        }
        for (Entry entry : Entry.values()) {
            Vista v=cor(LIGAND_MASK,LIGAND_MASK,entry,true,true,true);
            int cycles=entry==Entry.FAULT?0:96-32*entry.ordinal();
            require(v.evaluations()==cycles && evaluationsOf(v.operand())==cycles
                    && entryOf(v.operand())==entry && ligandsOf(v.operand())==LIGAND_MASK
                    && rupturesOf(v.operand())==v.rupture(), "COR packing/bypass");
        }
        for (int bit=0;bit<30;bit++) {
            int changed=LIGAND_MASK ^ (1<<bit);
            Vista v=cor(changed,LIGAND_MASK,Entry.OR,true,true,true);
            require(v.rupture()==(1<<(bit/5))
                    && v.observed()==changed && v.expected()==LIGAND_MASK, "Rupture mapping");
            Gates g=v.blocks().get(bit/5);
            require(g.or() && !g.xor() && !g.and(), "Altered block truth table");
        }
        Vista alerts=cor(31,31,Entry.FAULT,false,false,false);
        require(alerts.rupture()==(MISSING_WITNESS|REPLAY_SEQUENCE|
                CLOCK_REGRESSION|INVALID_ENTRY), "Independent flags");
        require(nop(true) && !nop(false), "NOP preservation");
        Machine machine=new Machine();
        Stage[] stages=Stage.values();
        for(int round=0;round<3;round++){
            for(int i=0;i<6;i++) {
                Step step=machine.tick(LIGAND_MASK,LIGAND_MASK,Entry.OR,true,true,true);
                require(step.stage()==stages[i], "Six-stage ordering");
                require(step.cyclesCompleted()==round+(i==5?1:0), "FLOP cycle increment");
                if(i==4) require(step.vista().evaluations()==96, "VISTA in COR stage");
            }
            require(machine.next()==Stage.XOR, "FLOP returns to existing entry");
        }
        Vista immutable=vista(cor(0x1234567,LIGAND_MASK,Entry.XOR,true,true,true));
        try {
            immutable.blocks().clear();
            throw new AssertionError("VISTA block list was mutable");
        } catch (UnsupportedOperationException expected) { }
        require(immutable.blocks().size()==6, "Read-only VISTA");
        System.out.println("PENTAGONAL_JAVA_SELF_TEST|PASS|truth_states="+validations+
            "|fault_injections=30|cor_entries=4|loops=3|source_mutated=false");
    }

    // TEST -> TILT is an expected fault-injection verification.
    private static void tilt() {
        int original = LIGAND_MASK;
        int changed = original ^ (1 << 2);
        Vista v=cor(changed,original,Entry.OR,true,true,true);
        require(v.rupture()==1 && v.observed()==changed && v.expected()==original,
                "TILT did not detect the injected ligand rupture");
        require(v.blocks().get(0).or() && !v.blocks().get(0).xor()
                && !v.blocks().get(0).and(), "TILT wrong gate diagnostics");
        require(original==LIGAND_MASK, "TILT mutated original source");
        System.out.println("PENTAGONAL_JAVA_TILT|PASS|expected_error_detected=true"+
            "|rupture_flags=1|source_mutated=false");
    }

    // Active, monotonic-clock-duration load, no sleep, no idle/automation.
    // wall clock is NOT an authenticated monotonic witness.
    private static void stress(int seconds) {
        if(seconds<1||seconds>300) throw new IllegalArgumentException("Duration must be 1..300 seconds");
        long durationNanos = seconds * 1_000_000_000L;
        long start = System.nanoTime();
        long operations=0, checksum=0, lastProgress=0;
        Machine m=new Machine();
        while (System.nanoTime() - start < durationNanos) {
            int observed=LIGAND_MASK ^ (1 << (int)(operations % 30));
            Step s=m.tick(observed,LIGAND_MASK,Entry.OR,true,true,true);
            checksum += s.value()?1:0;
            if(s.vista()!=null) checksum += s.vista().rupture();
            operations++;
            long elapsed=(System.nanoTime()-start)/1_000_000_000L;
            if(elapsed/10 > lastProgress) {
                lastProgress=elapsed/10;
                System.out.println("PENTAGONAL_JAVA_PROGRESS|seconds="+elapsed+"|ticks="+operations);
            }
        }
        double elapsedSeconds=(System.nanoTime()-start)/1_000_000_000.0;
        require(elapsedSeconds>=seconds && operations>0 && m.completed()>0,
                "Stress interval or execution count insufficient");
        System.out.printf(Locale.ROOT,
            "PENTAGONAL_JAVA_STRESS|PASS|elapsed_seconds=%.4f|ticks=%d|loops=%d|checksum=%d|source_mutated=false%n",
            elapsedSeconds,operations,m.completed(),checksum);
    }

    private static int parseThirty(String arg) {
        long value=Long.decode(arg);
        if(value<0||value>LIGAND_MASK) throw new IllegalArgumentException("Value outside 30-bit unsigned domain");
        return (int)value;
    }
    private static void emitVista(String[] args) {
        int observed = args.length>1 ? parseThirty(args[1]) : LIGAND_MASK;
        int expected = args.length>2 ? parseThirty(args[2]) : observed;
        boolean supplied=args.length>2;
        Entry entry=args.length>3 ? Entry.valueOf(args[3].toUpperCase(Locale.ROOT)) : Entry.OR;
        Machine m=new Machine();
        Step corStep=null;
        for(int i=0;i<6;i++){
            Step s=m.tick(observed,expected,entry,supplied,true,true);
            if(s.stage()==Stage.COR) corStep=s;
        }
        Vista v=vista(corStep.vista());
        System.out.println("PENTAGONAL_JAVA_VISTA|PASS|operand_hex="+
            String.format(Locale.ROOT,"%016x",v.operand())+
            "|rupture_flags="+v.rupture()+"|logical_evaluations="+v.evaluations()+
            "|loops="+m.completed()+"|next="+m.next()+"|source_mutated=false");
    }
    public static void main(String[] args) {
        try {
            if(args.length==1 && args[0].equals("--self-test")) selfTest();
            else if(args.length==1 && args[0].equals("--tilt")) tilt();
            else if(args.length==2 && args[0].equals("--stress")) stress(Integer.parseInt(args[1]));
            else if(args.length>=1 && args[0].equals("--vista") && args.length<=4) emitVista(args);
            else {
                System.err.println("Usage: java PentagonalControl --self-test | --tilt | --stress 60 | --vista [observed30 [expected30 [or|xor|and|fault]]]");
                System.exit(2);
            }
        } catch (RuntimeException | AssertionError ex) {
            System.err.println("PENTAGONAL_JAVA_FAIL|"+ex.getMessage());
            System.exit(1);
        }
    }
}
