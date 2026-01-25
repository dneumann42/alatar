#!/usr/bin/env tclsh

set home "$::env(HOME)"
set ssh_dir "$home/.ssh"

proc confirm {prompt} {
    set answer [readLine "$prompt (y/n) "]
    return [string match -nocase "y*" $answer]
}

proc uploadKeyToGithub {} {
    global ssh_dir
    if {[file exists $ssh_dir] == 0} {
	return;
    }
    set msg1 "Generate a token with `admin:public_key` scope at\n"
    set msg2 "https://github.com/settings/tokens"
    set token [readLine "$msg1$msg2\nGITHUB Token: "]
    if {$token == ""} {
	puts "Invalid input, try again."
	uploadKeyToGithub
	return;
    }

    set ls_results [exec ls $ssh_dir]
    puts "$ls_results"
    set keyname [readLine "Name of public key:"]
    set keypath "$ssh_dir/$keyname"
    puts "KEYPATH: $keypath"
    set publickey [slurp $keypath]
    set hostname [info hostname]
    set date [clock format [clock seconds] -format "%Y%m%d"]

    set title "$hostname-$date"
    set key "$publickey"
    set body [format {{"title": "%s", "key": "%s"}} $title $key]
 
    if {[catch {exec curl -L \
    		    -H "Accept: application/vnd.github.v3+json" \
    		    -H "Authorization: Bearer $token" \
    		    -H "X-GitHub-Api-Version: 2022-11-28" \
    		    https://api.github.com/user/keys \
		    -d "$body" 2>@1} result]} {
        puts "ERROR: Failed to upload public key to GitHub: $result"
        return
    }

    puts "Public key was uploaded to GITHUB."
}

if {[file exists $ssh_dir] == 0} {
    if {[confirm "SSH key not found, would you like to generate one?"]} {
	if {[catch {exec ssh-keygen <@stdin >@stdout 2>@stderr} result]} {
	    puts "ERROR: Failed to generate SSH key: $result"
	} elseif {[confirm "Do you want to upload your new key to github?"]} {
	    uploadKeyToGithub
        }
    }
}
