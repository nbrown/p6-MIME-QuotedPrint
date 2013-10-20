class MIME::QuotedPrint;

method encode(Blob $stuff --> Str) {
    my $encoded = '';

    my $linelen = 0;
    my $lastspace = False;
    for $stuff.list -> $byte {
        if 33 <= $byte <= 126 && $byte != 61 { # normal printable characters (less space, tab, and '=')
            $encoded ~= $byte.chr;
            $linelen++;
            $lastspace = False;
        } elsif $byte == 32 | 9 {   # tab and space are treated normally, but can't end a line
            $encoded ~= $byte.chr;
            $linelen++;
            $lastspace = True;
        } else {    # everything else gets encoded
            if $linelen > 72 { # make sure we have room for our 3-byte encoding
                $encoded ~= "=\n";
                $linelen = 0;
            }
            $encoded ~= "=" ~ sprintf("%02s", $byte.base(16));
            $linelen += 3;
            $lastspace = False;
        }

        # check line length (max 76 chars)
        if $linelen >= 75 {
            $encoded ~= "=\n";
            $linelen = 0;
            $lastspace = False;
        }
    }
    if $lastspace {
        $encoded ~= "=\n";
    }

    return $encoded;
}

method encode-str(Str $stuff --> Str) {
    return self.encode($stuff.encode('utf8'));
}

method decode(Str $stuff --> Buf) {
    my @codes;

    my $seq = '';
    for $stuff.comb -> $char {
        if $char eq "=" {
            $seq = "=";
        } elsif $char eq "\n" {
            $seq = "";
        } else {
            if $seq {
                $seq ~= $char;
            } else {
                @codes.push($char.ords[0]);
            }
        }

        if $seq.codes == 3 {
            $seq = $seq.substr(1,2);
            @codes.push(:16($seq));
            $seq = '';
        }
    }

    return Buf.new(@codes);
}

method decode-str(Str $stuff --> Str){
    return self.decode($stuff).decode('utf8');
}
