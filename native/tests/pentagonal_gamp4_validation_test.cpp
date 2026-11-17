// SPDX-License-Identifier: 0BSD
// GAMP 4-style supplier verification, not a regulated-use certification.
#include "../pentagonal_gates.hpp"
#include <array>
#include <bit>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits>
using namespace swe::pentagonal;
namespace {
unsigned failures=0;
void check(const char* id, bool ok, const char* what) {
 std::cout<<(ok?"PASS|":"FAIL|")<<id<<"|"<<what<<"\n"; failures+=!ok;
}
bool near(double a,double b) {return std::isfinite(a)&&std::abs(a-b)<1e-12;}
bool stack2(std::uint8_t v) {
 unsigned next=0;
 for(unsigned j=0;j<5;++j) {
  auto rotated=static_cast<std::uint8_t>(((v<<j)|(v>>(5u-j)))&31u);
  if(boolean_gates(rotated).xor_value) next|=1u<<j;
 }
 return boolean_gates(static_cast<std::uint8_t>(next)).xor_value;
}
bool stack3(std::uint8_t v) {
 unsigned next=0;
 for(unsigned j=0;j<5;++j) {
  auto rotated=static_cast<std::uint8_t>(((v<<j)|(v>>(5u-j)))&31u);
  if(stack2(rotated)) next|=1u<<j;
 }
 return boolean_gates(static_cast<std::uint8_t>(next)).xor_value;
}
}
int main() {
 bool ok=true;
 for(unsigned m=0;m<32;++m) {
  auto g=boolean_gates(static_cast<std::uint8_t>(m));
  unsigned n=std::popcount(m); std::array<double,5> f{};
  for(unsigned j=0;j<5;++j) f[j]=((m>>j)&1u)?1.0:0.0;
  PentagonalScores s{};
  ok &= pentagonal_scores(f,s)&&g.xor_value==((n&1u)!=0u)
    &&g.or_value==(n>0)&&g.and_value==(n==5)
    &&s.xor_score==static_cast<double>(g.xor_value)
    &&s.or_score==static_cast<double>(g.or_value)
    &&s.and_score==static_cast<double>(g.and_value);
 }
 check("URS-11",ok,"32 states match independent count reference and canonical scorer");

 PentagonalScores s{7,7,7,7,7};
 auto preserved=[&](){return s.legacy==7&&s.and_score==7&&s.or_score==7&&s.xor_score==7&&s.partial==7;};
 bool domain=!pentagonal_scores({0,0,-.01,0,0},s)&&preserved()
  &&!pentagonal_scores({0,0,1.01,0,0},s)&&preserved()
  &&!pentagonal_scores({0,0,std::numeric_limits<double>::infinity(),0,0},s)&&preserved()
  &&!pentagonal_scores({0,0,std::numeric_limits<double>::quiet_NaN(),0,0},s)&&preserved();
 domain &= pentagonal_scores({0,0,0,0,0},s)&&near(s.xor_score,0)&&near(s.or_score,0)&&near(s.and_score,0);
 domain &= pentagonal_scores({1,1,1,1,1},s)&&near(s.xor_score,1)&&near(s.or_score,1)&&near(s.and_score,1);
 domain &= pentagonal_scores({.5,.5,.5,.5,.5},s)&&near(s.xor_score,.5)&&near(s.or_score,.96875)&&near(s.and_score,.03125);
 check("URS-12",domain,"invalid and boundary ligands preserve output on rejection");

 bool layout=true;
 for(unsigned i=0;i<4;++i){
  const Entry e=static_cast<Entry>(i);
  const unsigned count=i==3?0:96u-i*32u;
  auto v=pentagonal_cor(ligand_mask,ligand_mask,e);
  layout &= entry_of(v.operand)==e && v.evaluations==count
   &&evaluations_of(v.operand)==count
   &&ligands_of(v.operand)==ligand_mask
   &&ruptures_of(v.operand)==v.rupture;
  layout &= i==3 ? (!v.valid_entry && ((v.rupture&invalid_entry)!=0)) :
    (v.valid_entry && v.rupture==0);
 }
 const auto packed=pack(Entry::xor_gate,0xffffffffu,65535u,65535u);
 layout &= ligands_of(packed)==ligand_mask && entry_of(packed)==Entry::xor_gate
   &&evaluations_of(packed)==65535u && ruptures_of(packed)==65535u;
 check("URS-13",layout,"64-bit 2-30-16-16 layout, bounds and four entry modes");

 bool flips=true;
 for(unsigned bit=0;bit<30;++bit) {
  const std::uint32_t observed=ligand_mask^(1u<<bit);
  const auto v=pentagonal_cor(observed,ligand_mask);
  const auto g=v.blocks[bit/5u];
  flips &= v.observed==observed && v.expected==ligand_mask
   &&v.rupture==(1u<<(bit/5u))&&!g.xor_value&&g.or_value&&!g.and_value;
 }
 check("URS-14",flips,"30 individual corruption injections flagged by block");

 auto a=pentagonal_cor(31,31,Entry::or_gate,false,true,true);
 auto b=pentagonal_cor(31,31,Entry::or_gate,true,false,true);
 auto c=pentagonal_cor(31,31,Entry::or_gate,true,true,false);
 auto d=pentagonal_cor(31,31,Entry::fault,false,false,false);
 check("URS-15",a.rupture==missing_witness&&b.rupture==replay_sequence
  &&c.rupture==clock_regression
  &&d.rupture==(missing_witness|replay_sequence|clock_regression|invalid_entry),
  "missing witness, replay, clock rollback and invalid selector distinct");

 const auto changed=ligand_mask^1u;
 const auto local=pentagonal_cor(changed,changed,Entry::or_gate,true);
 const auto absent=pentagonal_cor(changed,changed,Entry::or_gate,false);
 check("URS-16",local.rupture==0&&absent.rupture==missing_witness
  &&local.observed==changed&&absent.observed==changed,
  "self-comparison not authenticated; absent witness disclosed");

 check("URS-17",pentagonal_nop(true)&&!pentagonal_nop(false),"NOP preserves both states");

 Machine machine{};bool sequence=true;
 const Stage order[]={Stage::xor_gate,Stage::or_gate,Stage::and_gate,
  Stage::nop,Stage::cor,Stage::flop};
 for(unsigned repeat=0;repeat<3;++repeat) {
  bool prior=false;
  for(unsigned step=0;step<6;++step) {
   auto result=machine.tick(ligand_mask,ligand_mask);
   sequence &= result.stage==order[step]&&result.loops_completed==repeat+(step==5?1u:0u);
   if(step==2) prior=result.output;
   if(step==3) sequence &= result.output==prior;
   if(step==4) sequence &= result.vista.evaluations==96&&result.vista.rupture==0;
  }
  sequence &= machine.next==Stage::xor_gate && machine.loops==repeat+1u;
 }
 check("URS-18",sequence,"three complete XOR OR AND NOP COR FLOP cycles and return");

 const auto before=pentagonal_cor(0x1234567u,ligand_mask,Entry::xor_gate);
 const auto after=pentagonal_vista(before);
 bool vist=before.operand==after.operand&&before.observed==after.observed
  &&before.expected==after.expected&&before.rupture==after.rupture
  &&before.evaluations==after.evaluations&&before.entry==after.entry;
 for(unsigned i=0;i<6;++i)
  vist &= before.blocks[i].xor_value==after.blocks[i].xor_value
   &&before.blocks[i].or_value==after.blocks[i].or_value
   &&before.blocks[i].and_value==after.blocks[i].and_value;
 check("URS-19",vist,"VISTA returns full read-only snapshot");

 bool sweep=true;
 for(unsigned e=0;e<3;++e)
  sweep &= pentagonal_cor(0,0,static_cast<Entry>(e)).evaluations==96-32*e;
 check("URS-20",sweep,"COR bypass gives 96/64/32 logical evaluations");

 bool stacks=true;
 for(unsigned m=0;m<32;++m) {
  const auto v=static_cast<std::uint8_t>(m);
  stacks &= boolean_gates(v).xor_value==stack2(v)
         &&boolean_gates(v).xor_value==stack3(v);
 }
 check("URS-21",stacks,"depths one through three Boolean parity agree");

 bool blocks=true;
 for(unsigned i=0;i<6;++i) {
  const std::uint32_t vec=31u<<(5u*i);
  const auto v=pentagonal_cor(vec,vec);
  blocks &= v.rupture==0;
  for(unsigned j=0;j<6;++j) {
   blocks &= v.blocks[j].xor_value==(i==j)
    &&v.blocks[j].or_value==(i==j)
    &&v.blocks[j].and_value==(i==j);
  }
 }
 check("URS-22",blocks,"six block position mappings preserve endpoints");

 std::cout<<"GAMP4_STYLE_SUMMARY|"<<(failures?"FAIL":"PASS")
          <<"|cases=12|failures="<<failures<<"\n";
 return failures?1:0;
}
