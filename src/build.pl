#!/usr/bin/perl
# Builds the small playable ../prop-pilot.html (repo root, served at /prop-pilot) from the readable prop_pilot.src.html.
# ALWAYS edit src/prop_pilot.src.html, then run (from the repo root):  perl src/build.pl
# The game's <script> is stripped of full-line // comments, raw-deflated, base64'd and
# unpacked at load by the browser's DecompressionStream, then run as a normal <script>.
# The (already deflated) mesh blob MZ is kept outside the packed code.
use strict; use warnings; use MIME::Base64; use IO::Compress::RawDeflate qw(rawdeflate); use IO::Uncompress::RawInflate qw(rawinflate);
my $dir=__FILE__=~m{^(.*)/}?$1:'.';
open my $F,'<:raw',"$dir/prop_pilot.src.html" or die "no src: $!"; my $s=do{local $/;<$F>}; close $F;
$s=~m{^(.*<body>.*?)<script>\n?(.*)\n?</script>(</body></html>\s*)$}s or die "layout changed: expected one <script> at end of body";
my($head,$js,$tail)=($1,$2,$3);
$js=~s/const MZ="([A-Za-z0-9+\/=]+)"/const MZ=MZ_/ or die "MZ mesh blob not found"; my $mz=$1;
$js=~s/^[ \t]*\/\/[^\n]*\n//mg;   # full-line comments only
rawdeflate(\$js=>\my $z,-Level=>9) or die; rawinflate(\$z=>\my $chk) or die; die "roundtrip mismatch" unless $chk eq $js;
my $b=encode_base64($z,'');
my $out=$head.'<script>var MZ_="'.$mz.'";(async()=>{try{const s=document.createElement("script");s.textContent=await new Response(new Blob([Uint8Array.from(atob("'.$b.'"),c=>c.charCodeAt(0))]).stream().pipeThrough(new DecompressionStream("deflate-raw"))).text();document.body.appendChild(s)}catch(e){document.body.innerHTML=\'<p style="font:20px Georgia;padding:40px">Prop Pilot needs an up-to-date Chrome, Safari, Firefox or Edge.</p>\'}})()</script>'.$tail;
open my $O,'>:raw',"$dir/../prop-pilot.html" or die; print $O $out; close $O;
printf "built prop-pilot.html: %d bytes (source %d bytes)\n",length $out,length $s;
