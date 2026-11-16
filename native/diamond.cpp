// SPDX-License-Identifier: 0BSD
// Copyright (c) 2026 Paul Allen Cheek
// DIAMOND: one native C++20 command, source-preserving independent facets.
// Build from the unmodified, pinned Pentagonal XOR headers and source files.
#include "word_bridges.hpp"
#include "acoustic.hpp"
#include "pentagonal_xor_std_free.h"
#include "stability10d.hpp"
#include "deca_sigma.hpp"
#include "tri_pi.hpp"
#include "coreao.hpp"
#include "coreao_gain.hpp"
#include "coreo_stereo.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>
#if defined(_WIN32)
#include <io.h>
#else
#include <unistd.h>
#endif

// Compile the original five-channel guard as-is, remapping only the
// program entry symbol in THIS translation unit. The upstream file stays
// byte-for-byte unchanged. No security/AND/parity logic is reimplemented.
#define main swe_original_trust_guard_entry
#include "../external/pentagonal-xor-cpp20/shared/swe_guard.cpp"
#undef main

// The exploratory second-wave experiment is likewise compiled verbatim,
// not reimplemented or represented as a product/runtime prediction API.
#define main swe_original_second_wave_entry
#include "../external/pentagonal-xor-cpp20/tests/counterarccosine_secondwave_test.cpp"
#undef main

namespace {
using swe::word_bridges::json_string;
using swe::word_bridges::valid_utf8;
using swe::word_bridges::Language;
using swe::word_bridges::find;

struct Options {
    std::optional<double> watts;
    std::optional<double> gain_dbi;
    std::optional<double> deca;
    std::optional<double> fifth;
    std::optional<std::array<double,5>> features;
    std::optional<std::array<double,9>> ligands;
    std::optional<std::array<double,9>> measurements;
    std::string language = "en";
    std::string text, reading, meaning, source;
    std::string direction = "auto";
    std::string raw_stereo;
    std::optional<std::array<std::string,4>> metadata;
};

double number(std::string_view s) {
    const std::string value(s);
    std::size_t n = 0;
    const double x = std::stod(value,&n);
    if (n != value.size() || !std::isfinite(x))
        throw std::invalid_argument("Expected finite numeric operand");
    return x;
}
template<std::size_t N>
std::array<double,N> numbers(std::string_view s) {
    std::array<double,N> a{};
    std::size_t start=0;
    for(std::size_t i=0;i<N;++i) {
        const auto end=s.find(',',start);
        if ((i+1u<N && end==s.npos) || (i+1u==N && end!=s.npos))
            throw std::invalid_argument("Wrong number of comma-separated components");
        a[i]=number(s.substr(start,end==s.npos ? end : end-start));
        start=end==s.npos ? s.size() : end+1u;
    }
    return a;
}
void choose(Options& o,std::string_view key,std::string value) {
    if (key=="watts") o.watts=number(value);
    else if (key=="gain_dbi" || key=="gain-dbi") o.gain_dbi=number(value);
    else if (key=="deca") o.deca=number(value);
    else if (key=="fifth") o.fifth=number(value);
    else if (key=="features") o.features=numbers<5>(value);
    else if (key=="ligands") o.ligands=numbers<9>(value);
    else if (key=="measurements") o.measurements=numbers<9>(value);
    else if (key=="language") o.language=std::move(value);
    else if (key=="text") o.text=std::move(value);
    else if (key=="reading") o.reading=std::move(value);
    else if (key=="meaning") o.meaning=std::move(value);
    else if (key=="source") o.source=std::move(value);
    else if (key=="direction") o.direction=std::move(value);
    else if (key=="raw-stereo" || key=="raw_stereo") o.raw_stereo=std::move(value);
    else if (key=="metadata-url" || key=="metadata-path" ||
             key=="metadata-sha256" || key=="metadata-artifact") {
        if (!o.metadata) o.metadata=std::array<std::string,4>{};
        const unsigned slot=key=="metadata-url" ? 0u : key=="metadata-path" ? 1u :
                            key=="metadata-sha256" ? 2u : 3u;
        (*o.metadata)[slot]=std::move(value);
    }
    else throw std::invalid_argument("Unsupported input key: "+std::string(key));
}
std::string_view trim(std::string_view s) {
    while (!s.empty() && (s.front()==' ' || s.front()=='\t')) s.remove_prefix(1);
    while (!s.empty() && (s.back()==' ' || s.back()=='\t' || s.back()=='\r'))
        s.remove_suffix(1);
    return s;
}
Options from_pipe(Options opts,std::string_view record) {
    record=trim(record);
    if (record.empty()) return opts;
    if(record.find('=')==record.npos && record.find(';')==record.npos){
        opts.gain_dbi=number(record);
        return opts;
    }
    std::set<std::string> keys;
    while(!record.empty()) {
        const auto end=record.find(';');
        const auto field=trim(record.substr(0,end));
        const auto equal=field.find('=');
        if(equal==field.npos || equal==0u)
            throw std::invalid_argument("Piped record needs key=value fields");
        const auto key=trim(field.substr(0,equal));
        if(!keys.insert(std::string(key)).second)
            throw std::invalid_argument("Duplicate piped key");
        choose(opts,key,std::string(field.substr(equal+1)));
        if(end==record.npos) break;
        record.remove_prefix(end+1u);
    }
    return opts;
}
void str(std::ostream& out,std::string_view s) { json_string(out,s); }
void boolean(std::ostream& out,bool b) {out << (b?"true":"false");}
void report(const Options& o) {
    using namespace swe;
    if(!valid_utf8(o.text) || !valid_utf8(o.reading) || !valid_utf8(o.meaning) ||
       !valid_utf8(o.source)) throw std::invalid_argument("Word Bridges text is not valid UTF-8");
    const Language* lang=find(o.language);
    if(!lang) throw std::invalid_argument("Language code absent from pinned 348-edition catalog");
    if(o.direction!="ltr" && o.direction!="rtl" && o.direction!="auto")
        throw std::invalid_argument("Direction must be auto, ltr or rtl");
    if((!o.raw_stereo.empty() && (o.measurements||o.ligands)) ||
       (o.measurements && o.ligands))
        throw std::invalid_argument("Conflicting acoustic input authorities");
    const double w=o.watts.value_or(1.0), g=o.gain_dbi.value_or(9.0);
    if(g < -100.0 || g > 100.0) throw std::invalid_argument("Gain outside [-100,100] dBi");
    const auto rf=coreao::rf_gain::apply(w);
    if(!rf.passed()) throw std::invalid_argument("Original +9 dBi RF guard rejected power");
    const double delta=g == 9.0 ? 1.0 : std::pow(10.0,(g-9.0)/10.0);
    const double linear=rf.gain_linear*delta, eirp=rf.output_eirp_watts*delta;
    if(!std::isfinite(delta)||!std::isfinite(linear)||linear<=0.0||
       !std::isfinite(eirp)||(w!=0.0 && eirp==0.0))
        throw std::invalid_argument("RF overflow or underflow");
    const double recovered=g==9.0?rf.recovered_input_watts:eirp/linear;
    const double residual=coreao::normalized_residual(w,recovered);
    if(!std::isfinite(residual)||residual>1e-12)
        throw std::invalid_argument("RF roundtrip residual too high");

    std::optional<native::Acoustic> acoustic;
    if(!o.raw_stereo.empty()) {
        std::ifstream audio(o.raw_stereo,std::ios::binary);
        if(!audio) throw std::invalid_argument("Cannot open supplied float32LE stereo source");
        acoustic=native::measure_float32le(audio);
    }
    stability10d::Result stability{};
    if(acoustic||o.measurements){
        double measures[9]{};
        const auto& m=acoustic?acoustic->measurements:*o.measurements;
        for(unsigned i=0;i<9;++i) measures[i]=m[i];
        if(!stability10d::from_measurements(measures,stability))
            throw std::invalid_argument("Original normalization rejected acoustic measurements");
    } else {
        double nine[9]{};
        for(unsigned i=0;i<9;++i) nine[i]=o.ligands?(*o.ligands)[i]:0.5;
        if(!stability10d::calculate(nine,stability))
            throw std::invalid_argument("Original Stability-10D rejected nine ligands");
    }
    char hex[13]{};
    stability10d::hex(stability,hex);
    double five[5]{};
    for(unsigned i=0;i<5;++i) five[i]=o.features?(*o.features)[i]:stability.ligands[i];
    for(double v:five)
        if(!std::isfinite(v)||v<0||v>1)
            throw std::invalid_argument("Original XOR domain is [0,1]");
    const Features5 f{five[0],five[1],five[2],five[3],five[4]};
    const auto scores=swe_pxor_scores5(f);
    const double fifth=swe_pxor_fifth_root(o.fifth.value_or(-32.0));
    const auto trace=deca_sigma::run(o.deca.value_or(2.0));
    if(!trace.admissible||!deca_sigma::witnesses_return(trace))
        throw std::invalid_argument("Original DecaSigma witness rejected CORE");
    const auto tri=tri_pi::inspect(trace);
    const auto core=coreao::inspect(trace);
    if(!tri.passed()||!core.passed())
        throw std::invalid_argument("Original route audit failed");

    // Immutable stereo source with the original forward/inverse/Z-fold.
    const std::vector<float> fallback{1.0f,-2.0f,3.0f,-4.0f};
    const auto& stereo=acoustic?acoustic->stereo:fallback;
    const auto frames=static_cast<unsigned long long>(stereo.size()/2u);
    std::vector<coreo_stereo::Quad> quads(static_cast<std::size_t>(frames));
    for(unsigned long long i=0u;i<frames;++i){
        if(!coreo_stereo::forward_at(stereo.data(),frames,i,quads[static_cast<std::size_t>(i)]))
            throw std::invalid_argument("Original COREO stereo forward failed");
        float left=0.0f,right=0.0f;
        if(!coreo_stereo::reverse_at(quads[static_cast<std::size_t>(i)],left,right)||
           left!=stereo[static_cast<std::size_t>(2*i)]||
           right!=stereo[static_cast<std::size_t>(2*i+1)])
            throw std::invalid_argument("Original COREO stereo inverse failed");
    }
    const auto audit=coreo_stereo::inspect(stereo.data(),frames,quads.data());
    if(!audit.admissible||audit.largest_disagreement!=0.0)
        throw std::invalid_argument("Original COREO Z-fold audit failed");

    if(!swe::self_test())
        throw std::runtime_error("Original five-channel trust guard self-test failed");
    bool metadata_checked=false,metadata_valid=false;
    if(o.metadata){
        metadata_checked=true;
        const auto& m=*o.metadata;
        for(const auto& field:m) if(field.empty())
            throw std::invalid_argument("All four trust-guard metadata fields required");
        const auto checks=swe::inspect(m[0],m[1],m[2],m[3]);
        metadata_valid=swe::conjunction(checks);
        if(!metadata_valid) throw std::invalid_argument("Original five-channel AND policy rejected metadata");
    }
    // Execute original exploratory test without allowing its console line
    // to corrupt the machine-readable single-record JSON output.
    struct Capture {
        std::ostringstream buffer;
        std::streambuf* old;
        Capture():old(std::cout.rdbuf(buffer.rdbuf())){}
        ~Capture(){std::cout.rdbuf(old);}
    };
    int study_code=1;
    std::string study_note;
    {
        Capture capture;
        study_code=swe_original_second_wave_entry();
        study_note=capture.buffer.str();
    }
    if(study_code!=0)throw std::runtime_error("Original counterarccosine research witness failed");

    std::ostringstream out;
    out<<std::setprecision(17);
    out<<"{\"schema\":\"SWE-DIAMOND-CXX20-v1\",\"canonical_source_sha\":"
       <<"\"fb23b40480476c98e992762ace37761b6fd8ba0e\""
       <<",\"runtime\":\"native-cxx20\",\"trained_model_used\":false,"
       <<"\"transcript_generated\":false,\"foreign_runtime_modules\":false";
    out<<",\"language\":{\"catalog_count\":"<<word_bridges::language_count<<",\"code\":";
    str(out,lang->code);
    out<<",\"english\":";str(out,lang->english);
    out<<",\"autonym\":";str(out,lang->autonym);
    out<<",\"wikipedia\":";str(out,lang->wikipedia);
    out<<",\"direction\":";str(out,o.direction);
    out<<",\"character_text\":";str(out,o.text);
    out<<",\"reading_supplied\":";str(out,o.reading);
    out<<",\"meaning_supplied\":";str(out,o.meaning);
    out<<",\"source_supplied\":";str(out,o.source);
    out<<",\"translation_generated\":false,\"utf8_preserved\":true}";
    out<<",\"parity\":{\"xor\":"<<swe_pxor_xor_parity_arr(five)
       <<",\"and\":"<<scores.and_score<<",\"or\":"<<scores.or_score
       <<",\"partial\":"<<scores.partial<<",\"legacy_fifth_root\":"
       <<scores.legacy<<"},\"fifth_root\":{\"value\":"<<fifth
       <<",\"reference_fixture\":";boolean(out,!o.fifth);
    out<<"},\"stability\":{\"hexabyte\":";str(out,hex);
    out<<",\"scalar\":"<<stability.stability<<",\"rings\":[";
    for(unsigned i=0;i<3;++i){if(i)out<<',';out<<stability.rings[i];}
    out<<"],\"ligands\":[";
    for(unsigned i=0;i<9;++i){if(i)out<<',';out<<stability.ligands[i];}
    out<<"],\"measurements_source\":";
    str(out,acoustic?"supplied-raw-stereo":o.measurements?"supplied-measurements":o.ligands?"supplied-ligands":"synthetic-reference");
    out<<"}";
    out<<",\"deca_sigma\":{\"operations\":";
    str(out,deca_sigma::operations);
    out<<",\"stages\":[";
    for(unsigned i=0;i<11;++i){if(i)out<<',';out<<trace.stages[i];}
    out<<"],\"passed\":true,\"reference_fixture\":";boolean(out,!o.deca);
    out<<"},\"tri_pi\":{\"forward\":";boolean(out,tri.forward);
    out<<",\"reverse\":";boolean(out,tri.reverse);
    out<<",\"zfold\":";boolean(out,tri.zfold);
    out<<"},\"coreao\":{\"scalar\":"<<core.scalar<<",\"passed\":true}";
    out<<",\"rf\":{\"domain\":\"idealized-directional-eirp\","
       <<"\"gain_dbi\":"<<g<<",\"input_watts\":"<<w
       <<",\"gain_linear\":"<<linear<<",\"eirp_watts\":"<<eirp
       <<",\"canonical_9dbi_eirp_watts\":"<<rf.output_eirp_watts
       <<",\"recovered_watts\":"<<recovered<<",\"residual\":"<<residual
       <<",\"implementation\":";
    str(out,g==9.0?"original-fixed-9dbi":"separate-rf-offset-v1");
    out<<",\"reference_watts\":";boolean(out,!o.watts);
    out<<",\"amplified_audio\":false}";
    out<<",\"coreo_stereo\":{\"frames\":"<<frames
       <<",\"largest_disagreement\":"<<audit.largest_disagreement
       <<",\"source\":\""<<(acoustic?"supplied-raw-stereo":"synthetic-reference")<<"\"}";
    out<<",\"trust_guard\":{\"original_self_test\":true,\"metadata_supplied\":";
    boolean(out,metadata_checked);
    out<<",\"five_channel_AND_passed\":";
    boolean(out,metadata_checked&&metadata_valid);
    out<<",\"actual_sha256_digest_verified\":false}";
    out<<",\"counterarccosine\":{\"original_test_passed\":true,"
       <<"\"production_operator\":false,\"measured_antenna\":false}";
    out<<",\"acoustic\":{\"supplied_raw_frames\":"
       <<(acoustic?acoustic->measurements[0]:0.0)
       <<",\"pearson_lr\":"<<(acoustic?acoustic->pearson_lr:0.0)
       <<",\"input_measurement_present\":";
    boolean(out,acoustic.has_value()||o.measurements.has_value());
    out<<"},\"reference_values_not_measurements\":";
    boolean(out,!acoustic&&!o.measurements&&!o.ligands);
    out<<"}";
    std::cout<<out.str()<<'\n';
}
void usage() {
    std::cout<<"diamond: all-on canonical C++20 computation; no vendor runtime\n"
        "Usage: diamond [--watts N] [--gain-dbi N] [--language CODE] "
        "[--text UTF8] [--reading UTF8] [--meaning UTF8] [--source UTF8] "
        "[--direction auto|ltr|rtl] [--raw-stereo FILE] "
        "[--features CSV5] [--ligands CSV9] [--measurements CSV9] "
        "[--deca N] [--fifth N] [--metadata-url URL ...]\n"
        "Pipe a single dBi number (11) or key=value;key=value records to stdin.\n"
        "--languages emits 348 frozen catalog entries; no automatic translation.\n";
}
bool piped_stdin() {
#if defined(_WIN32)
    return _isatty(_fileno(stdin))==0;
#else
    return isatty(fileno(stdin))==0;
#endif
}
} // namespace

int diamond_main(int argc,char** argv) {
    try {
        Options options{};
        for(int i=1;i<argc;++i) {
            const std::string_view key=argv[i];
            if(key=="--help"||key=="-h"){usage();return 0;}
            if(key=="--languages"){swe::word_bridges::list_languages(std::cout);return 0;}
            if(!key.starts_with("--")||i+1>=argc)
                throw std::invalid_argument("Expected --key value; see --help");
            choose(options,key.substr(2),argv[++i]);
        }
        if(piped_stdin()){
            bool emitted=false;
            std::string line;
            unsigned n=0;
            while(std::getline(std::cin,line)){
                if(trim(line).empty())continue;
                if(line.size()>65536u || ++n>10000u)
                    throw std::invalid_argument("Input line/record limit exceeded");
                report(from_pipe(options,line));
                emitted=true;
            }
            if(!emitted) report(options);
        } else report(options);
        return 0;
    }catch(const std::exception& e){
        std::cerr<<"diamond rejected input: "<<e.what()<<'\n';
        return 2;
    }
}


#if defined(_WIN32)
// Windows narrow argv uses the active ANSI codepage, not necessarily UTF-8.
// Read the OS UTF-16 command line and encode Unicode scalars explicitly;
// refuse unpaired surrogate sequences. No lossy fallback.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
int wmain(int argc, wchar_t** wide_argv) {
    std::vector<std::string> arguments;
    std::vector<char*> pointers;
    arguments.reserve(static_cast<std::size_t>(argc));
    pointers.reserve(static_cast<std::size_t>(argc));
    for (int i=0;i<argc;++i) {
        const int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
            wide_argv[i], -1, nullptr, 0, nullptr, nullptr);
        if(size<=0) {
            std::cerr << "diamond rejected malformed UTF-16 CLI argument\n";
            return 2;
        }
        std::string value(static_cast<std::size_t>(size), '\0');
        const int written = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
            wide_argv[i], -1, value.data(), size, nullptr, nullptr);
        if(written != size) {
            std::cerr << "diamond rejected malformed UTF-16 CLI argument\n";
            return 2;
        }
        value.pop_back(); // Remove only the NUL terminator.
        arguments.push_back(std::move(value));
    }
    for (auto& value:arguments) pointers.push_back(value.data());
    return diamond_main(argc, pointers.data());
}
#else
int main(int argc,char** argv) { return diamond_main(argc,argv); }
#endif
