#!/usr/bin/env tclsh

set home "$::env(HOME)"
set ssh_dir "$home/.ssh"

proc read-line {prompt} {
    puts -nonewline "$prompt"
    flush stdout
    gets stdin input
    return $input
}

proc confirm {prompt} {
    set answer [read-line "$prompt (y/n) "]
    return [string match -nocase "y*" $answer]
}

proc uploadKeyToGithub {} {
    global ssh_dir
    if {[file exists $ssh_dir] == 0} {
	return;
    }
    set msg1 "Generate a token with `admin:public_key` scope at\n"
    set msg2 "https://github.com/settings/tokens"
    set token [read-line "$msg1$msg2\nGITHUB Token: "]
    if {$token == ""} {
	puts "Invalid input, try again."
	uploadKeyToGithub
	return;
    }

    set ls_results [exec ls $ssh_dir]
    puts "$ls_results"
    set keyname [read-line "Name of public key:"]
    set keypath "$ssh_dir/$keyname"
    puts "KEYPATH: $keypath"
    set publickey [slurp $keypath]
    set hostname [info hostname]
    set date [clock format [clock seconds] -format "%Y%m%d"]

    set title "$hostname-$date"
    set key "$publickey"
    set body [format {{"title": "%s", "key": "%s"}} $title $key]
 
    set result [catch {exec curl -L \
    		    -H "Accept: application/vnd.github.v3+json" \
    		    -H "Authorization: Bearer $token" \
    		    -H "X-GitHub-Api-Version: 2022-11-28" \
    		    https://api.github.com/user/keys \
		    -d "$body"}]

    puts "Public key was uploaded to GITHUB."
}

if {[file exists $ssh_dir] == 0} {
    if {[confirm "SSH key not found, would you like to generate one?"]} {
	catch {exec ssh-keygen}
	if {[confirm "Do you want to upload your new key to github?"]} {
	    uploadKeyToGithub
        }	
    }
}
